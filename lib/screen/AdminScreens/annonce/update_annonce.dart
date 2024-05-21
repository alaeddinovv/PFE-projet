import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfeprojet/Model/annonce/annonce_admin_model.dart';
import 'package:pfeprojet/component/components.dart';
import 'package:pfeprojet/component/drop_down_wilaya.dart';
import 'package:pfeprojet/screen/AdminScreens/annonce/cubit/annonce_cubit.dart';

class EditAnnoncePage extends StatefulWidget {
  final AnnonceAdminData
      annonceModel; // Assuming AnnonceModel is your data model

  const EditAnnoncePage({Key? key, required this.annonceModel})
      : super(key: key);

  @override
  _EditAnnoncePageState createState() => _EditAnnoncePageState();
}

class _EditAnnoncePageState extends State<EditAnnoncePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _wilayaController;
  late TextEditingController _dairaController;
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.annonceModel.type);
    _descriptionController =
        TextEditingController(text: widget.annonceModel.description);
    _wilayaController = TextEditingController(text: widget.annonceModel.wilaya);
    _dairaController = TextEditingController(text: widget.annonceModel.commune);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _wilayaController.dispose();
    _dairaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool canPop = true;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          if (canPop == true) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Annonce'),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                // padding: const EdgeInsets.all(16),
                children: <Widget>[
                  BlocBuilder<AnnonceCubit, AnnonceState>(
                    builder: (context, state) {
                      if (state is UpdateAnnonceLoadingState) {
                        return const LinearProgressIndicator();
                      }
                      return const SizedBox(height: 30);
                    },
                  ),
                  defaultForm3(
                    context: context,
                    controller: _titleController,
                    type: TextInputType.text,
                    valid: (String value) {
                      if (value.isEmpty) {
                        return 'Type Must Not Be Empty';
                      }
                    },
                    prefixIcon: const Icon(
                      Icons.keyboard_arrow_right_sharp,
                      color: Colors.grey,
                    ),
                    labelText: "TYPE DE L'ANNONCE",
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  defaultForm3(
                    context: context,
                    controller: _descriptionController,
                    type: TextInputType.text,
                    valid: (String value) {
                      if (value.isEmpty) {
                        return 'Contenu Must Not Be Empty';
                      }
                    },
                    prefixIcon: const Icon(
                      Icons.keyboard_arrow_right_sharp,
                      color: Colors.grey,
                    ),
                    maxline: 3,
                    labelText: "contenu de l'annonce",
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20),
                  DropdownScreen(
                    selectedDaira: _dairaController,
                    selectedWilaya: _wilayaController,
                  ),
                  const SizedBox(height: 20),
                  BlocConsumer<AnnonceCubit, AnnonceState>(
                    listener: (context, state) {
                      if (state is UpdateAnnonceLoadingState) {
                        canPop = false;
                      } else {
                        canPop = true;
                      }
                      if (state is UpdateAnnonceStateGood) {
                        // Handle success
                        showToast(msg: "Succes", state: ToastStates.success);
                        AnnonceCubit.get(context)
                            .getMyAnnonce(cursor: "")
                            .then((value) {
                          Navigator.pop(context);
                        });
                      } else if (state is UpdateAnnonceStateBad) {
                        // Handle failure
                        showToast(msg: "Failed", state: ToastStates.error);
                      }
                    },
                    builder: (context, state) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            defaultSubmit2(
                              text: 'Update',
                              background: Colors.blueAccent,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  AnnonceCubit.get(context).updateAnnonce(
                                    id: widget.annonceModel.id!,
                                    type: _titleController.text,
                                    description: _descriptionController.text,
                                    wilaya: _wilayaController.text,
                                    commune: _dairaController.text,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
