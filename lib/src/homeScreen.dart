import 'package:final_project_doa/logic/home_cubit.dart';
import 'package:final_project_doa/sheets/add_medicine_sheet.dart';
import 'package:final_project_doa/src/models/medicine.dart';
import 'package:final_project_doa/widgets/dose_card.dart';
import 'package:final_project_doa/widgets/empty_state.dart';
import 'package:final_project_doa/widgets/next_dose_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';



class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = [
      Medicine(
        id: 'm1',
        name: 'باراسيتامول',
        dosage: '500mg',
        times: [
          const DoseTime(time: TimeOfDay(hour: 8, minute: 0), note: 'بعد الإفطار'),
          const DoseTime(time: TimeOfDay(hour: 14, minute: 0)),
        ],
        days: {
          Weekday.sun, Weekday.mon, Weekday.tue, Weekday.wed,
          Weekday.thu, Weekday.fri, Weekday.sat
        },
      ),
      Medicine(
        id: 'm2',
        name: 'أموكسيسيلين',
        dosage: '1 كبسولة',
        times: [
          const DoseTime(time: TimeOfDay(hour: 21, minute: 0), note: 'قبل النوم'),
        ],
        days: {Weekday.sun, Weekday.tue, Weekday.thu, Weekday.sat},
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider(
        create: (_) => HomeCubit(seed),
        child: Scaffold(
          backgroundColor: const Color(0xfffffbf2),
          appBar: AppBar(
            backgroundColor: const Color(0xfffffbf2),
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'تذكير الدواء',
              style: TextStyle(color: Color(0xff33484d), fontWeight: FontWeight.bold),
            ),
          ),
          floatingActionButton: Builder(
            builder: (context) => FloatingActionButton.extended(
              backgroundColor: const Color(0xffa1dcc0),
              foregroundColor: Colors.white,
              onPressed: () async {
                final created = await showModalBottomSheet<Medicine>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddMedicineSheet(),
                );
                if (created != null) {
                  // ignore: use_build_context_synchronously
                  context.read<HomeCubit>().addMedicine(created);
                }
              },
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (ctx, i) {
                                  final d = state.today[i];
                                  final taken = state.taken[d.keyId] ?? false;
                                  final past = d.dateTime.isBefore(DateTime.now());

                                  return DoseCard(
                                    medName: d.med.name,
                                    dosage: d.med.dosage,
                                    note: d.note,
                                    time: d.dateTime,
                                    taken: taken,
                                    isPast: past,
                                    onSnooze: () => context
                                        .read<HomeCubit>()
                                        .snooze(d.keyId, const Duration(minutes: 10)),
                                    onToggle: () => context
                                        .read<HomeCubit>()
                                        .toggleTaken(d.keyId, !taken),
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

  void _openAdd(BuildContext context) async {
    final created = await showModalBottomSheet<Medicine>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMedicineSheet(),
    );
    if (created != null) {
      // ignore: use_build_context_synchronously
      context.read<HomeCubit>().addMedicine(created);
    }
  }
}
