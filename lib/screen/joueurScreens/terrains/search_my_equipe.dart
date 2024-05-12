// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfeprojet/Model/houssem/equipe_model.dart';
import 'package:pfeprojet/screen/joueurScreens/terrains/cubit/terrain_cubit.dart';

class SearchTest extends StatefulWidget {
  final TextEditingController equipeIdController;
  final Function(EquipeModelData)? onEquipeSelected;
  // final Function(String) onSelectedJoueur; // Add this line

  SearchTest({
    Key? key,
    required this.equipeIdController,
    this.onEquipeSelected,
    // required this.onSelectedJoueur, // Add this line
  }) : super(key: key);

  @override
  State<SearchTest> createState() => _SearchTestState();
}

class _SearchTestState extends State<SearchTest> {
  bool showResults = true;
  EquipeModelData? selectedEquipe;
  Timer? _debounce;
  late ScrollController _controller;
  TextEditingController searchController = TextEditingController();
  late final TerrainCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = TerrainCubit.get(context);

    _controller = ScrollController()
      ..addListener(() {
        if (_controller.offset >= _controller.position.maxScrollExtent &&
            !_controller.position.outOfRange &&
            TerrainCubit.get(context).cursorIdEqeuipe != "") {
          TerrainCubit.get(context).searchEquipe(
              cursor: TerrainCubit.get(context).cursorIdEqeuipe,
              nomEquipe: searchController.text);
        }
      });
  }

  void _selectJoueur(EquipeModelData equipe) {
    setState(() {
      selectedEquipe = equipe;
      showResults = false;
      widget.equipeIdController.text =
          equipe.id!; // Update the parent's TextEditingController
    });
    if (widget.onEquipeSelected != null) {
      widget.onEquipeSelected!(equipe);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Cancel the timer when the widget is disposed
    searchController.dispose();
    cubit.cursorIdEqeuipe = '';
    cubit.equipeSearch = [];

    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      TerrainCubit.get(context).searchEquipe(nomEquipe: value);
      showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Stack(
          children: [
            TextFormField(
              controller: searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search players...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
                labelStyle: const TextStyle(color: Colors.deepPurple),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.deepPurple),
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
            ),
            BlocConsumer<TerrainCubit, TerrainState>(
              listener: (context, state) {},
              builder: (context, state) {
                bool hasResults = cubit.equipeSearch.isNotEmpty;
                bool isLoading = state is GetSearchEquipeLoading;
                bool isSearchTextEmpty = searchController.text.isEmpty;
                bool shouldShowResults =
                    hasResults || (isLoading && !isSearchTextEmpty);
                if (!showResults) {
                  return const SizedBox();
                } else {
                  return Container(
                    margin: const EdgeInsets.only(top: 60),
                    child: Visibility(
                      visible: shouldShowResults,
                      child: SizedBox(
                        height: 250,
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                controller: _controller,
                                itemBuilder: (context, index) {
                                  var joueur = cubit.equipeSearch[index];
                                  return Card(
                                    color:
                                        Colors.green.shade50.withOpacity(0.8),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 4,
                                    child: ListTile(
                                      title: Text(joueur.nom!),
                                      subtitle: Text(
                                          'Age: ${joueur.capitaineId!.nom} - Position: ${joueur.id}'),
                                      onTap: () {
                                        print(joueur.id);
                                        _selectJoueur(joueur);
                                        widget.equipeIdController.text =
                                            joueur.id!;
                                        // widget.onSelectedJoueur(joueur.id!);
                                      },
                                    ),
                                  );
                                },
                                itemCount: cubit.equipeSearch.length,
                                separatorBuilder:
                                    (BuildContext context, int index) =>
                                        const Divider(),
                              ),
                            ),
                            if (isLoading &&
                                !isSearchTextEmpty &&
                                cubit.cursorIdEqeuipe != '')
                              const CircularProgressIndicator(),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
