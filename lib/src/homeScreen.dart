import 'dart:io' show Platform;

import 'package:final_project_doa/logic/home_cubit.dart';
import 'package:final_project_doa/sheets/add_medicine_sheet.dart';
import 'package:final_project_doa/src/models/medicine.dart';
import 'package:final_project_doa/src/services/notification_service.dart';
import 'package:final_project_doa/widgets/dose_card.dart';
import 'package:final_project_doa/widgets/empty_state.dart';
import 'package:final_project_doa/widgets/next_dose_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ✅ Cubit واحد يظل أثناء hot reload
  late final HomeCubit _cubit = HomeCubit([]);

  Future<void> _openSehhaty(BuildContext context) async {
    const String url =
        'https://www.moh.gov.sa/eServices/Sehhaty/Pages/default.aspx';
    final uri = Uri.parse(url);

    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      if (await launchUrl(uri, mode: LaunchMode.platformDefault)) return;
      if (await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
        ),
      ))
        return;
      throw 'No handler';
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح موقع صحتي')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider.value(
        value: _cubit,
        child: Scaffold(
          backgroundColor: const Color(0xfffffbf2),
          appBar: AppBar(
            backgroundColor: const Color(0xfffffbf2),
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'تذكير الدواء',
              style: TextStyle(
                color: Color(0xff33484d),
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8.0),
                child: TextButton.icon(
                  onPressed: () => _openSehhaty(context),
                  icon: const Icon(
                    Icons.health_and_safety,
                    color: Color(0xff33484d),
                  ),
                  label: const Text(
                    'صحتي',
                    style: TextStyle(
                      color: Color(0xff33484d),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xff33484d),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
            ],
          ),

          floatingActionButton: Builder(
            builder: (context) => FloatingActionButton.extended(
              backgroundColor: const Color(0xffa1dcc0),
              foregroundColor: Colors.white,
              onPressed: () => _openAdd(context),
              icon: const Icon(Icons.add),
              label: const Text('إضافة دواء'),
            ),
          ),

          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  final title = state.next == null
                      ? null
                      : '${state.next!.med.name} — ${state.next!.med.dosage}'
                            '${state.next!.note != null ? " — ${state.next!.note}" : ''}';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              [
                                    _chipBtn(
                                      'Test الآن',
                                      icon: Icons.notifications_active_outlined,
                                      onTap: () async {
                                        final svc =
                                            NotificationService.instance;
                                        await svc.ensureAndroidChannel();
                                        await svc.showNow(
                                          id: 999,
                                          title: 'Test now',
                                          body: 'وصلك؟',
                                        );
                                      },
                                    ),
                                    _chipBtn(
                                      'مسح الكل',
                                      icon: Icons.delete_sweep_outlined,
                                      onTap: () async {
                                        await NotificationService.instance
                                            .cancelAll();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'تم مسح كل الإشعارات المجدولة',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    _chipBtn(
                                      'عرض Pending',
                                      icon: Icons.list_alt_outlined,
                                      onTap: () async {
                                        final pending =
                                            await NotificationService.instance
                                                .pluginPending();
                                        // ignore: avoid_print
                                        print(
                                          '[PENDING] count=${pending.length}',
                                        );
                                        for (final p in pending) {
                                          // ignore: avoid_print
                                          print(
                                            '[PENDING] id=${p.id} title=${p.title} body=${p.body}',
                                          );
                                        }
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Pending: ${pending.length}',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ]
                                  .map(
                                    (w) => Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        end: 8,
                                      ),
                                      child: w,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      NextDoseBanner(
                        title: title,
                        nextTime: state.next?.dateTime,
                        until: state.untilNext,
                      ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'جرعات اليوم',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff33484d),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffa1dcc0).withOpacity(.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${state.today.length} جرعة',
                              style: const TextStyle(color: Color(0xff33484d)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: state.today.isEmpty
                            ? EmptyState(onAddPressed: () => _openAdd(context))
                            : ListView.separated(
                                itemCount: state.today.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (ctx, i) {
                                  final d = state.today[i];
                                  final taken = state.taken[d.keyId] ?? false;
                                  final past = d.dateTime.isBefore(
                                    DateTime.now(),
                                  );

                                  return DoseCard(
                                    medName: d.med.name,
                                    dosage: d.med.dosage,
                                    note: d.note,
                                    time: d.dateTime,
                                    taken: taken,
                                    isPast: past,
                                    onToggle: () => context
                                        .read<HomeCubit>()
                                        .toggleTaken(d.keyId, !taken),

                                    // ✅ المهمة: استخدم keyId هنا
                                    onRemove: () => context
                                        .read<HomeCubit>()
                                        .removeDose(d.keyId),

                                    imagePath: d.med.imagePath,
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _chipBtn(
    String label, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff33484d),
        side: BorderSide(color: const Color(0xffa1dcc0).withOpacity(.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _openAdd(BuildContext context) async {
    final created = await showModalBottomSheet<Medicine>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMedicineSheet(),
    );
    if (created != null && context.mounted) {
      context.read<HomeCubit>().addMedicine(created);
    }
  }
}
