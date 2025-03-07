import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/theme_extensions.dart';
import 'package:immich_mobile/providers/search/people.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/services/api.service.dart';
import 'package:immich_mobile/utils/image_url_builder.dart';
import 'package:immich_mobile/widgets/search/person_name_edit_form.dart';

@RoutePage()
class PeopleCollectionPage extends HookConsumerWidget {
  const PeopleCollectionPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(getAllPeopleProvider);
    final headers = ApiService.getRequestHeaders();
    final formFocus = useFocusNode();
    final ValueNotifier<String?> search = useState(null);

    showNameEditModel(
      String personId,
      String personName,
    ) {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return PersonNameEditForm(personId: personId, personName: personName);
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final isPortrait = context.orientation == Orientation.portrait;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: search.value == null,
            title: search.value != null
                ? TextField(
                    focusNode: formFocus,
                    onTapOutside: (_) => formFocus.unfocus(),
                    onChanged: (value) => search.value = value,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(left: 24),
                      filled: true,
                      fillColor: context.primaryColor.withOpacity(0.1),
                      hintStyle: context.textTheme.bodyLarge?.copyWith(
                        color: context.themeData.colorScheme.onSurfaceSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: context.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: context.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: context.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: context.colorScheme.primary.withAlpha(150),
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: context.colorScheme.primary,
                      ),
                      hintText: 'search_filter_people_hint'.tr(),
                    ),
                    autofocus: true,
                  )
                : Text('people'.tr()),
            actions: [
              IconButton(
                icon: Icon(search.value != null ? Icons.close : Icons.search),
                onPressed: () {
                  search.value = search.value == null ? '' : null;
                },
              ),
            ],
          ),
          body: people.when(
            data: (people) {
              if (search.value != null) {
                people = people.where((person) {
                  return person.name
                      .toLowerCase()
                      .contains(search.value!.toLowerCase());
                }).toList();
              }
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 6 : 3,
                  childAspectRatio: 0.85,
                  mainAxisSpacing: isPortrait && isTablet ? 36 : 0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 32),
                itemCount: people.length,
                itemBuilder: (context, index) {
                  final person = people[index];

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.pushRoute(
                            PersonResultRoute(
                              personId: person.id,
                              personName: person.name,
                            ),
                          );
                        },
                        child: Material(
                          shape: const CircleBorder(side: BorderSide.none),
                          elevation: 3,
                          child: CircleAvatar(
                            maxRadius: isTablet ? 120 / 2 : 96 / 2,
                            backgroundImage: NetworkImage(
                              getFaceThumbnailUrl(person.id),
                              headers: headers,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => showNameEditModel(person.id, person.name),
                        child: person.name.isEmpty
                            ? Text(
                                'add_a_name'.tr(),
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: context.colorScheme.primary,
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Text(
                                  person.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  );
                },
              );
            },
            error: (error, stack) => const Text("error"),
            loading: () => const CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
