import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgetbook/src/models/models.dart';
import 'package:widgetbook/src/providers/organizer_provider.dart';
import 'package:widgetbook/src/providers/organizer_state.dart';
import 'package:widgetbook/src/repositories/selected_story_repository.dart';
import 'package:widgetbook/src/repositories/story_repository.dart';
import 'package:widgetbook/src/services/filter_service.dart';

import '../../helper/provider_helper.dart';
import '../../helper/widget_test_helper.dart';
import '../../mocks/filter_service_mock.dart';

extension _WidgetTesterProviderExtension on WidgetTester {
  Future<OrganizerProvider> pumpProvider({
    required OrganizerState initialState,
    required StoryRepository storyRepository,
    required SelectedStoryRepository selectedStoryRepository,
    FilterService? filterService,
  }) async {
    final mockedFilterService = filterService ?? FilterServiceMock();
    final provider = await pumpBuilderAndReturnProvider<OrganizerProvider>(
      OrganizerBuilder(
        initialState: initialState,
        storyRepository: storyRepository,
        selectedStoryRepository: selectedStoryRepository,
        filterService: mockedFilterService,
        child: Container(),
      ),
    );
    return provider;
  }
}

void main() {
  late StoryRepository storyRepository;
  late SelectedStoryRepository selectedStoryRepository;

  final story1 = WidgetbookUseCase(
    name: 'Story 1',
    builder: (context) => Container(),
  );

  final story2 = WidgetbookUseCase(
    name: 'Story 2',
    builder: (context) => Container(),
  );

  setUp(
    () {
      storyRepository = StoryRepository(
        initialConfiguration: <String, WidgetbookUseCase>{
          story1.name: story1,
          story2.name: story2,
        },
      );
      selectedStoryRepository = SelectedStoryRepository();
    },
  );

  group(
    '$OrganizerProvider',
    () {
      testWidgets(
        'expands $WidgetbookWidget when the selected story changes',
        (WidgetTester tester) async {
          var provider = await tester.pumpProvider(
            initialState: OrganizerState.unfiltered(
              categories: [
                WidgetbookCategory(
                  name: 'Category 1',
                  widgets: [
                    WidgetbookWidget(
                      name: 'Widget 1',
                      useCases: [
                        story1,
                      ],
                    ),
                  ],
                ),
              ],
            ),
            storyRepository: storyRepository,
            selectedStoryRepository: selectedStoryRepository,
          );

          provider = await tester.invokeMethodAndReturnPumpedProvider(
            () {
              selectedStoryRepository.setItem(story1);
            },
          );

          expect(
            provider.state.allCategories.first.widgets.first.isExpanded,
            isTrue,
          );
        },
      );

      testWidgets(
        'togglesExpander of $WidgetbookWidget',
        (WidgetTester tester) async {
          final widgetElement = WidgetbookWidget(
            name: 'Widget 1',
            useCases: [],
          );
          var provider = await tester.pumpProvider(
            initialState: OrganizerState.unfiltered(
              categories: [
                WidgetbookCategory(
                  name: 'Category 1',
                  widgets: [widgetElement],
                ),
              ],
            ),
            storyRepository: storyRepository,
            selectedStoryRepository: selectedStoryRepository,
          );

          provider = await tester.invokeMethodAndReturnPumpedProvider(
            () {
              provider.toggleExpander(widgetElement);
            },
          );

          expect(
            provider.state,
            equals(
              OrganizerState.unfiltered(
                categories: [
                  WidgetbookCategory(
                    name: 'Category 1',
                    widgets: [
                      WidgetbookWidget(
                        name: 'Widget 1',
                        isExpanded: true,
                        useCases: [],
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      testWidgets(
        'expands $WidgetbookWidget when the selected story changes',
        (WidgetTester tester) async {
          var provider = await tester.pumpProvider(
            initialState: OrganizerState.unfiltered(
              categories: [
                WidgetbookCategory(
                  name: 'Category 1',
                  folders: [
                    WidgetbookFolder(
                      name: 'Folder 1',
                    ),
                  ],
                  widgets: [
                    WidgetbookWidget(
                      name: 'Widget 1',
                      isExpanded: true,
                      useCases: [story1, story2],
                    ),
                  ],
                ),
              ],
            ),
            storyRepository: storyRepository,
            selectedStoryRepository: selectedStoryRepository,
          );

          provider = await tester.invokeMethodAndReturnPumpedProvider(
            () {
              provider.update(
                [
                  WidgetbookCategory(
                    name: 'Category 1',
                    folders: [
                      WidgetbookFolder(
                        name: 'Folder 1',
                      ),
                    ],
                    widgets: [
                      // Note that this WidgetElement does not have the isExpanded
                      // property set to true
                      WidgetbookWidget(
                        name: 'Widget 1',
                        useCases: [
                          story1,
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          );

          // Its still expected that the new structures has the isExpanded
          // property set to true
          expect(
            provider.state,
            equals(
              OrganizerState.unfiltered(
                categories: [
                  WidgetbookCategory(
                    name: 'Category 1',
                    folders: [
                      WidgetbookFolder(
                        name: 'Folder 1',
                      ),
                    ],
                    widgets: [
                      // Note that this WidgetElement does have the isExpanded
                      // property set to true
                      WidgetbookWidget(
                        name: 'Widget 1',
                        isExpanded: true,
                        useCases: [
                          story1,
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      testWidgets(
        'resets filter when resetFilter is called',
        (WidgetTester tester) async {
          final folder = WidgetbookFolder(
            name: 'Folder 1',
          );
          final category = WidgetbookCategory(
            name: 'Category 1',
            folders: [
              folder,
            ],
            widgets: [
              WidgetbookWidget(
                name: 'Widget 1',
                isExpanded: true,
                useCases: [
                  story1,
                  story2,
                ],
              ),
            ],
          );

          final filteredCategory = WidgetbookCategory(
            name: 'Category 1',
            folders: [
              folder,
            ],
          );

          var provider = await tester.pumpProvider(
            initialState: OrganizerState(
              allCategories: [
                category,
              ],
              filteredCategories: [
                filteredCategory,
              ],
              searchTerm: 'does not really matter',
            ),
            storyRepository: storyRepository,
            selectedStoryRepository: selectedStoryRepository,
          );

          provider = await tester.invokeMethodAndReturnPumpedProvider(
            () {
              provider.resetFilter();
            },
          );

          expect(
            provider.state,
            equals(
              OrganizerState.unfiltered(
                categories: [
                  category,
                ],
              ),
            ),
          );
        },
      );

      testWidgets(
        'invokes $FilterService when filter is called',
        (WidgetTester tester) async {
          final folder = WidgetbookFolder(
            name: 'Folder 1',
          );
          final category = WidgetbookCategory(
            name: 'Category 1',
            folders: [
              folder,
            ],
            widgets: [
              WidgetbookWidget(
                name: 'Widget 1',
                isExpanded: true,
                useCases: [
                  story1,
                  story2,
                ],
              ),
            ],
          );

          const searchTerm = 'does not really matter';

          final filterService = FilterServiceMock();
          when(
            () => filterService.filter(
              searchTerm,
              [
                category,
              ],
            ),
          ).thenReturn(
            [
              category,
            ],
          );

          var provider = await tester.pumpProvider(
            initialState: OrganizerState.unfiltered(categories: [
              category,
            ]),
            storyRepository: storyRepository,
            selectedStoryRepository: selectedStoryRepository,
            filterService: filterService,
          );

          provider = await tester.invokeMethodAndReturnPumpedProvider(
            () {
              provider.filter(
                searchTerm,
              );
            },
          );

          verify(
            () => filterService.filter(
              searchTerm,
              [
                category,
              ],
            ),
          ).called(1);

          expect(
            provider.state,
            equals(
              OrganizerState(
                allCategories: [
                  category,
                ],
                filteredCategories: [category],
                searchTerm: searchTerm,
              ),
            ),
          );
        },
      );

      testWidgets(
        '.of returns $OrganizerProvider instance',
        (WidgetTester tester) async {
          await tester.pumpWidgetWithMaterialApp(
            OrganizerBuilder(
              initialState: OrganizerState.unfiltered(
                categories: const [],
              ),
              selectedStoryRepository: selectedStoryRepository,
              storyRepository: storyRepository,
              filterService: FilterServiceMock(),
              child: Container(),
            ),
          );

          final BuildContext context = tester.element(find.byType(Container));
          final provider = OrganizerProvider.of(context);
          expect(
            provider,
            isNot(null),
          );
        },
      );
    },
  );
}
