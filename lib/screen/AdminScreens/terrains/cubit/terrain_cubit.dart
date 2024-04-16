import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:pfeprojet/Api/constApi.dart';
import 'package:pfeprojet/Api/httplaravel.dart';
import 'package:pfeprojet/Model/error_model.dart';
import 'package:pfeprojet/Model/non_reservable_time_block.dart';
import 'package:pfeprojet/Model/terrain_model.dart';
import 'package:pfeprojet/Model/user_model.dart';
import 'dart:convert' as convert;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'package:pfeprojet/component/components.dart';

part 'terrain_state.dart';

class TerrainCubit extends Cubit<TerrainState> {
  TerrainCubit() : super(TerrainInitial());

  static TerrainCubit get(context) => BlocProvider.of<TerrainCubit>(context);

//?---------------------------------------- TerrainHomeScreen-----------------------------------------------------------------
  List<TerrainModel> terrains = [];
  Future<void> getMyTerrains() async {
    emit(GetMyTerrainsLoading());
    await Httplar.httpget(path: GETMYTERRAINS).then((value) {
      if (value.statusCode == 200) {
        var jsonResponse = convert.jsonDecode(value.body) as List;
        terrains =
            jsonResponse.map((item) => TerrainModel.fromJson(item)).toList();
        emit(GetMyTerrainsStateGood()); // Pass the list here
      } else {
        var jsonResponse =
            convert.jsonDecode(value.body) as Map<String, dynamic>;
        emit(ErrorTerrainsState(errorModel: ErrorModel.fromJson(jsonResponse)));
      }
    }).catchError((e) {
      print(e.toString());
      emit(GetMyTerrainsStateBad());
    });
  }

//? -----------------------------------------Details.dart------------------------------------------
  int indexSlide = 0;
  void setCurrentSlide(int index) {
    indexSlide = index;
    emit(TerrainSlideChanged());
  }

  bool showStadiumDetails =
      false; // false = show reservation grid, true = show stadium details

  void toggleView(int index) {
    bool desiredState = index ==
        1; // Assuming 0 is for the reservation grid and 1 is for stadium details
    if (showStadiumDetails != desiredState) {
      showStadiumDetails = desiredState;
      emit(TerrainViewToggled());
    }
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    emit(TerrainDateChangedState());
  }

  List<String> generateTimeSlots(
      String sTemps, String eTemps, List<dynamic> nonReservable) {
    DateTime startTime = DateFormat("HH:mm")
        .parse(sTemps); // time format from server is HH:mm string
    DateTime endTime = DateFormat("HH")
        .parse(eTemps); // time format from server is HH:mm string
    List<String> timeSlots = [];

    while (startTime.isBefore(endTime)) {
      String slot = DateFormat('HH:mm').format(startTime);
      timeSlots.add(slot);
      startTime = startTime.add(const Duration(hours: 1, minutes: 0));
    }

    return timeSlots;
  }

// ?-----------------------------------------Reserve.dart------------------------------------------
  void checkUserById({required String id}) {
    emit(LoadinCheckUserByIdState());
    Httplar.httpget(
      path: getJouerById + id,
    ).then((value) {
      print(getJouerById + id);
      if (value.statusCode == 200) {
        var jsonResponse =
            convert.jsonDecode(value.body) as Map<String, dynamic>;
        print(jsonResponse);
        // emit(TerrainViewToggled());

        emit(CheckUserByIdStateGood(
            dataJoueurModel: DataJoueurModel.fromJson(jsonResponse)));
      } else {
        var jsonResponse =
            convert.jsonDecode(value.body) as Map<String, dynamic>;
        emit(ErrorState(errorModel: ErrorModel.fromJson(jsonResponse)));
      }
    }).catchError((e) {
      print(e.toString());
      emit(CheckUserByIdStateBad());
    });
  }

  Future<void> addReservation({
    Map<String, dynamic>? model,
    String? id_terrain,
  }) async {
    emit(AddReservationLoadingState());
    await Httplar.httpPost(
            path: RESERVERTERRAINWITHADMIN + id_terrain!, data: model!)
        .then((value) {
      if (value.statusCode == 201) {
        emit(AddReservationStateGood());
      } else {
        var jsonResponse =
            convert.jsonDecode(value.body) as Map<String, dynamic>;
        emit(ErrorState(errorModel: ErrorModel.fromJson(jsonResponse)));
        print(jsonResponse.toString());
      }
    }).catchError((e) {
      print(e.toString());
      emit(AddReservationStateBad());
    });
  }

  DateTime selectedDate = DateTime.now();

//? ------------------------------Create_terrain.dart-------------------------------------------------
  List<NonReservableTimeBlock> nonReservableTimeBlocks = [];
  bool canAddTimeBlock(NonReservableTimeBlock newBlock) {
    for (var block in nonReservableTimeBlocks) {
      if (block.day == newBlock.day) {
        // Check if the times overlap

        return false; // Found overlapping time
      }
    }

    return true; // No overlap found
  }

  void editeOneOfNonReservableTimeBlock(int? index) {
    emit(EditingNonReservableTimeBlock(index: index));
  }

  void addNonReservableTimeBlock(NonReservableTimeBlock block) {
    if (canAddTimeBlock(block)) {
      nonReservableTimeBlocks.add(block);
      emit(AddNonReservableTimeBlockState());
    } else {
      emit(DublicatedAddNonReservableTimeBlockState());
    }
  }

  void removeNonReservableTimeBlock(int index) {
    nonReservableTimeBlocks.removeAt(index);
    emit(RemoveNonReservableTimeBlockState());
  }

  void selectedDayChanged(String day) {
    emit(SelectedDayChangedState(selctedDay: day));
  }

  void clearNonReservableTimeBlocks() {
    nonReservableTimeBlocks.clear();
    images.clear();
  }

  final ImagePicker _picker = ImagePicker();
  List<File> images = [];
  Future<void> pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    List<File> selectedImages =
        pickedFiles.map((file) => File(file.path)).toList();
    for (var image in selectedImages) {
      if (images.length < 3) {
        await FlutterImageCompress.compressAndGetFile(
          image.absolute.path,
          '${image.path}.jpg',
          quality: 10,
        ).then((value) {
          images.add(File(value!.path));
        });
        // images.add(image);
      } else {
        showToast(
            msg: "You can only add up to 3 images.", state: ToastStates.error);
        break;
      }
    }
    emit(PickImageState());
  }

  void removeImage(int index) {
    images.removeAt(index);
    emit(RemoveImageState());
  }

  List<String> linkProfileImg = [];

  Future<void> updateProfileImg() async {
    for (var image in images) {
      await firebase_storage.FirebaseStorage.instance
          .ref()
          .child('terrains/${Uri.file(image.path).pathSegments.last}')
          .putFile(image)
          .then((p0) async {
        await p0.ref.getDownloadURL().then((value) {
          linkProfileImg.add(value);
          print(linkProfileImg);
          // emit(UploadProfileImgAndGetUrlStateGood());  //! bah matro7ch  LodingUpdateUserStateGood() t3 Widget LinearProgressIndicator
        }).catchError((e) {
          print(e.toString());
          emit(UploadTerrainImageAndAddUrlStateBad());
        });
      });
    }
  }

  Future<void> creerTarrain({
    Map<String, dynamic>? model,
  }) async {
    emit(CreerTerrainLoadingState());
    if (images.isNotEmpty) {
      await updateProfileImg();
    }
    if (linkProfileImg.isNotEmpty) {
      model!.addAll({"photos": linkProfileImg});
    }

    await Httplar.httpPost(path: ADDTERRAIN, data: model!).then((value) {
      if (value.statusCode == 201) {
        emit(CreerTerrainStateGood());
      } else {
        var jsonResponse =
            convert.jsonDecode(value.body) as Map<String, dynamic>;
        emit(ErrorState(errorModel: ErrorModel.fromJson(jsonResponse)));
        print(jsonResponse.toString());
      }
    }).catchError((e) {
      print(e.toString());
      emit(CreerTerrainStateBad());
    });
  }
}
