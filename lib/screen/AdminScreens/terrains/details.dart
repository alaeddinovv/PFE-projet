import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pfeprojet/Api/color.dart';
import 'package:pfeprojet/Model/terrain_model.dart';
import 'package:pfeprojet/component/components.dart';
import 'package:pfeprojet/screen/AdminScreens/home/cubit/home_admin_cubit.dart';
import 'package:pfeprojet/screen/AdminScreens/terrains/cubit/terrain_cubit.dart';
import 'package:pfeprojet/screen/AdminScreens/terrains/location/terrain_location.dart';
import 'package:pfeprojet/screen/AdminScreens/terrains/reservation_player_info.dart';
import 'package:pfeprojet/screen/AdminScreens/terrains/reserve.dart';
import 'package:pfeprojet/screen/AdminScreens/terrains/update_terrain.dart';

// ignore: must_be_immutable
class TerrainDetailsScreen extends StatefulWidget {
  TerrainModel terrainModel;
  TerrainDetailsScreen({super.key, required this.terrainModel});

  @override
  State<TerrainDetailsScreen> createState() => _TerrainDetailsScreenState();
}

class _TerrainDetailsScreenState extends State<TerrainDetailsScreen> {
  List<String> timeSlots = [];
  @override
  void initState() {
    timeSlots = TerrainCubit.get(context).generateTimeSlots(
        widget.terrainModel.heureDebutTemps!,
        widget.terrainModel.heureFinTemps!);
    TerrainCubit.get(context).fetchReservations(
        terrainId: widget.terrainModel.id!,
        date: TerrainCubit.get(context).selectedDate);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = TerrainCubit.get(context);

    final CarouselController _controller = CarouselController();
    var screenHeight = MediaQuery.of(context).size.height;
    // var screenWidth = MediaQuery.of(context).size.width;

    return BlocListener<TerrainCubit, TerrainState>(
      listener: (context, state) {
        if (state is UpdateTerrainStateGood) {
          setState(() {
            widget.terrainModel = state
                .terrainModel; // Update the local model with the new details
          });
        }
        if (state is AddReservationStateGood) {
          cubit.fetchReservations(
              terrainId: widget.terrainModel.id!, date: cubit.selectedDate);
          // sendNotificationToJoueur(title: 'accept Reservation', body: body, adminId: adminId)
        }
        if (state is DeleteReservationStateGood) {
          cubit.fetchReservations(
              terrainId: widget.terrainModel.id!, date: cubit.selectedDate);
        }
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // navigatAndReturn(context: context, page: SearchTest());
          },
        ),
        appBar: AppBar(
          title: const Text('Terrain Details'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              BlocBuilder<TerrainCubit, TerrainState>(
                builder: (context, state) {
                  return carouselSliderWithIndicator(
                      _controller, screenHeight, cubit);
                },
              ),
              SizedBox(
                height: screenHeight * 0.015,
              ),
              BlocBuilder<TerrainCubit, TerrainState>(
                builder: (context, state) {
                  return togeleReserveOrShowDescription(cubit, context);
                },
              ),
              BlocBuilder<TerrainCubit, TerrainState>(
                builder: (context, state) {
                  if (cubit.showStadiumDetails) {
                    return descriptionInfo(screenHeight, context);
                  } else {
                    return reservationGrid(screenHeight, cubit, context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Column reservationGrid(
      double screenHeight, TerrainCubit terrainCubit, BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: SizedBox(
            height: screenHeight * 0.08,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0;
                    i < 7;
                    i++) // Display 7 days and allow user to select a date in the last index
                  GestureDetector(
                    onTap: () {
                      DateTime selectedDate =
                          DateTime.now().add(Duration(days: i));
                      terrainCubit.selectDate(selectedDate);
                      terrainCubit.fetchReservations(
                          terrainId: widget.terrainModel.id!,
                          date: terrainCubit.selectedDate);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: terrainCubit.selectedDate.day ==
                                DateTime.now().add(Duration(days: i)).day
                            ? Colors.blue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      // padding: const EdgeInsets.symmetric(horizontal: 10),
                      // alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE')
                                .format(DateTime.now().add(Duration(days: i))),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: terrainCubit.selectedDate.day ==
                                      DateTime.now().add(Duration(days: i)).day
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            DateFormat('d')
                                .format(DateTime.now().add(Duration(days: i))),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: terrainCubit.selectedDate.day ==
                                      DateTime.now().add(Duration(days: i)).day
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    await dateTimePicker(context, terrainCubit);
                    terrainCubit.fetchReservations(
                        terrainId: widget.terrainModel.id!,
                        date: terrainCubit.selectedDate);
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: BlocBuilder<TerrainCubit, TerrainState>(
            builder: (context, state) {
              if (state is GetReservationLoadingState) {
                return const Center(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (state is GetReservationStateBad ||
                  state is ErrorState) {
                return const Center(
                  child: Text('Failed to fetch reservations'),
                );
              } else {
                DateTime date = terrainCubit
                    .selectedDate; // changed with the selectedDate from listview
                String dayOfWeek =
                    DateFormat('EEEE').format(date); // 'Sunday', 'Monday', etc.
                List<String> nonReservableHours =
                    []; //! Initialize with empty list (if no non-reservable hours are available)

                // Populate nonReservableHours based on selected day from nonReservableTimeBlocks
                for (var block
                    in widget.terrainModel.nonReservableTimeBlocks!) {
                  if (block.day == dayOfWeek || block.day == 'All') {
                    nonReservableHours.addAll(block.hours!.map((hour) => hour
                        .toString())); // Ensure hours are in string format if they aren't already
                  }
                }
                List<String> hourPayments = [];
                for (var block in terrainCubit.reservationList) {
                  if (block.jour!.month + block.jour!.day + block.jour!.year ==
                      terrainCubit.selectedDate.month +
                          terrainCubit.selectedDate.day +
                          terrainCubit.selectedDate.year) {
                    hourPayments.add(block.heureDebutTemps!);
                  }
                }

                return Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: timeSlots.length,
                      itemBuilder: (context, index) {
                        bool isCharge = hourPayments.contains(timeSlots[index]);
                        bool isReservable =
                            !nonReservableHours.contains(timeSlots[index]) &&
                                !isCharge;
                        return GestureDetector(
                          onTap: () {
                            print('Selected time slot: ${timeSlots[index]}');
                            if (isReservable) {
                              String hour = timeSlots[index];
                              print(timeSlots[index]);
                              navigatAndReturn(
                                  context: context,
                                  page: Reserve(
                                      date: terrainCubit.selectedDate,
                                      hour: hour,
                                      idTerrain: widget.terrainModel.id!));
                            } else if (isCharge) {
                              terrainCubit.reservationPlayerInfo(
                                  terrainId: widget.terrainModel.id!,
                                  date: terrainCubit.selectedDate,
                                  heure_debut_temps: timeSlots[index],
                                  payment: true);

                              navigatAndReturn(
                                  context: context,
                                  page: ReservationPlayerInfo());
                            }
                          },
                          child: itemGridViewReservation(nonReservableHours,
                              hourPayments, timeSlots, index),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    _buildColorIndex(),
                  ],
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Padding descriptionInfo(double screenHeight, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            height: screenHeight * 0.02,
          ),
          Row(
            children: [
              const Icon(Icons.location_on),
              const SizedBox(
                width: 8,
              ),
              RichText(
                text: TextSpan(
                  // Default style for all spans
                  style: DefaultTextStyle.of(context).style,
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'Address: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: widget.terrainModel.adresse!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              const Icon(Icons.phone),
              const SizedBox(
                width: 8,
              ),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'Telephone: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: HomeAdminCubit.get(context)
                          .adminModel!
                          .telephone!
                          .toString(),
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              const Icon(Icons.groups_2_rounded),
              const SizedBox(
                width: 8,
              ),
              RichText(
                  text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  const TextSpan(
                      text: 'Nombre de joueurs: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: "${widget.terrainModel.capacite} joueurs",
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ))
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              const Icon(Icons.sports_soccer_rounded),
              const SizedBox(
                width: 8,
              ),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(
                        text: 'État du terrain: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: widget.terrainModel.etat!,
                        style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          const Text("More:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(
            height: 8,
          ),
          Text(
            widget.terrainModel.description!,
            textAlign: TextAlign.center,
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              iconSize: 30,
              onPressed: () {
                navigatAndReturn(
                    context: context,
                    page: LocationTErrain(
                      terrainId: widget.terrainModel.id!,
                      location: LatLng(
                          widget.terrainModel.coordonnee!.latitude!,
                          widget.terrainModel.coordonnee!.longitude!),
                    ));
              },
              icon: const Icon(
                Icons.location_on_outlined,
                color: Colors.blue,
              ),
            ),
          ),
          defaultSubmit2(
              text: "UPDATE TERRAIN",
              onPressed: () {
                navigatAndReturn(
                    context: context,
                    page: EditTerrainPage(terrainModel: widget.terrainModel));
              })
        ],
      ),
    );
  }

  ToggleButtons togeleReserveOrShowDescription(
      TerrainCubit terrainCubit, BuildContext context) {
    return ToggleButtons(
      onPressed: (int index) {
        terrainCubit.toggleView(index);
      },
      isSelected: [
        !terrainCubit.showStadiumDetails,
        terrainCubit.showStadiumDetails,
      ],
      constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width / 2 - 10, minHeight: 40),
      children: const [
        Text('Reservation'),
        Text('Description'),
      ],
    );
  }

  Stack carouselSliderWithIndicator(CarouselController _controller,
      double screenHeight, TerrainCubit terrainCubit) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          carouselController: _controller,
          options: CarouselOptions(
            height: screenHeight * 0.2,
            initialPage: terrainCubit.indexSlide,
            viewportFraction: 1,
            // autoPlay: true,
            enlargeCenterPage: true,

            onPageChanged: (index, reason) {
              terrainCubit.setCurrentSlide(index);
            },
          ),
          items: widget.terrainModel.photos!.isEmpty
              ? [
                  Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                        ),
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 100,
                        ),
                      );
                    },
                  ),
                ]
              : widget.terrainModel.photos!.map((imagePath) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: imagePath,
                          fit: BoxFit.fill,
                          placeholder: (context, url) => Container(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      );
                    },
                  );
                }).toList(),
        ),
        Positioned(
          bottom: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                List.generate(widget.terrainModel.photos!.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: terrainCubit.indexSlide == index ? 20.0 : 8.0,
                height: 8.0,
                margin:
                    const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                decoration: BoxDecoration(
                  color: terrainCubit.indexSlide == index
                      ? Colors.blue
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Container itemGridViewReservation(
    List<String> isReservable,
    List<String> isCharge,
    List<String> timeSlots,
    int index,
  ) {
    Color backgroundColor =
        Colors.green[500]!; // Default to green for available slots

    // If the slot is not reservable (blocked), it gets a red color
    if (isReservable.contains(timeSlots[index])) {
      backgroundColor = Colors.red; // Red for non-reservable (blocked) slots
    }
    // If the slot is charged (booked or taken), it gets a gray color
    else if (isCharge.contains(timeSlots[index])) {
      backgroundColor = Colors.grey[300]!; // Gray for charged (booked) slots
    }

    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        timeSlots[index],
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> dateTimePicker(
      BuildContext context, TerrainCubit terrainCubit) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: terrainCubit.selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != terrainCubit.selectedDate) {
      terrainCubit.selectDate(picked);
    }
  }
}

Widget _buildColorIndex() {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color Index:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          _buildColorItem(greenConst, 'Available for booking'),
          _buildColorItem(Colors.red[300]!, 'Blocked by stadium owner'),
          _buildColorItem(Colors.grey[300]!, 'Booked by other players'),
          _buildColorItem(Colors.blue[300]!, 'Your approved booking'),
          _buildColorItem(Colors.yellow[300]!, 'Your pending booking'),
        ],
      ),
    ),
  );
}

Widget _buildColorItem(Color color, String label) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 8),
        Text(label),
      ],
    ),
  );
}
