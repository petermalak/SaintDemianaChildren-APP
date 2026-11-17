import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class TourAction {
  final String name;
  final String does;

  const TourAction(this.name, this.does);
}

class TourStep {
  final String title;
  final String summary;
  final List<TourAction> actions;

  const TourStep({
    required this.title,
    required this.summary,
    required this.actions,
  });
}

class TourBeat {
  final int tabIndex;
  final String kicker;
  final String title;
  final String body;
  final bool button;

  const TourBeat({
    required this.tabIndex,
    required this.kicker,
    required this.title,
    required this.body,
    required this.button,
  });
}

List<TourBeat> tourBeats(List<String> labels, {required String? programRole}) {
  final beats = <TourBeat>[];
  for (var i = 0; i < labels.length; i++) {
    final step = tourStepFor(labels[i], programRole: programRole);
    beats.add(TourBeat(
      tabIndex: i,
      kicker: 'التبويب ${i + 1} من ${labels.length}',
      title: step.title,
      body: step.summary,
      button: false,
    ));
    for (var a = 0; a < step.actions.length; a++) {
      final action = step.actions[a];
      beats.add(TourBeat(
        tabIndex: i,
        kicker: '${step.title} · الزر ${a + 1} من ${step.actions.length}',
        title: action.name,
        body: action.does,
        button: true,
      ));
    }
  }
  return beats;
}

class ScreenTourCard extends StatelessWidget {
  final int index;
  final int count;
  final TourBeat beat;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onClose;

  const ScreenTourCard({
    super.key,
    required this.index,
    required this.count,
    required this.beat,
    required this.onBack,
    required this.onNext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final last = index + 1 >= count;
    return Material(
      color: AppColors.backgroundCard,
      elevation: 16,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.accentGold, width: 4)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    beat.kicker,
                    style: const TextStyle(
                      color: AppColors.primaryMaroon,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'إغلاق',
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: AppColors.primaryMaroon),
                ),
              ],
            ),
            Text(
              beat.button ? 'الزر على الشاشة' : 'انظر التبويب الذهبي في الشريط السفلي',
              style: const TextStyle(
                color: AppColors.primaryMaroon,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              beat.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              beat.body,
              style: const TextStyle(
                fontSize: 16,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: count == 0 ? 0 : (index + 1) / count,
                minHeight: 6,
                backgroundColor: AppColors.primaryCream,
                color: AppColors.primaryMaroon,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (index > 0) ...[
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: onBack,
                      child: const Text('السابق', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMaroon,
                        foregroundColor: AppColors.accentWhite,
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      onPressed: onNext,
                      child: Text(last ? 'إنهاء' : 'التالي'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

TourStep tourStepFor(String label, {required String? programRole}) {
  final role = programRole;
  final servant = role == 'class' || role == 'amin';
  final publisher = role == 'score' || role == 'class' || role == 'amin';
  return switch (label) {
    'الرئيسية' => TourStep(
        title: 'الرئيسية',
        summary: role == 'makhdoum'
            ? 'رمز الحضور ظاهر هنا. أظهره لخادم الفصل.'
            : 'ملخص اليوم. صورة الحساب فوق تفتح الملف، وتبديل الدور، والخروج.',
        actions: [
          if (role == 'makhdoum')
            const TourAction('رمز الحضور', 'يفضل ظاهر من غير نت. الخادم يمسحه من تبويب الحضور.'),
          const TourAction('علامة الاستفهام', 'تعيد هذا الشرح من أول تبويب.'),
        ],
      ),
    'الأعضاء' => const TourStep(
        title: 'الأعضاء',
        summary: 'أولاد الفصل اللي قدامك.',
        actions: [
          TourAction('البحث', 'يلاقي الولد بالاسم.'),
          TourAction('اسم الولد', 'يفتح بياناته.'),
        ],
      ),
    'الحضور' => const TourStep(
        title: 'حضور الكنيسة',
        summary: 'فصل الكنيسة من زر تسجيل حضور. فصل حديثي التخرج من نفس القائمة: اختَر الفصل والنوع وامسح الرمز.',
        actions: [
          TourAction('تسجيل حضور', 'لفصل الكنيسة. بيحفظ الحضور القديم، ويضيف تايو الفصل لو التفعيل ظاهر.'),
          TourAction('مسح الرمز', 'لفصل حديثي التخرج. يسجل العشية أو الاجتماع أو القداس.'),
          TourAction('تسجيل يدوي', 'لفصل حديثي التخرج لو الولد نسي الموبايل. لازم سبب.'),
        ],
      ),
    'المزيد' => const TourStep(
        title: 'المزيد',
        summary: 'باقي شغل الكنيسة.',
        actions: [
          TourAction('الأخبار', 'منشورات الفصل.'),
          TourAction('الافتقاد', 'زيارات الكنيسة، غير افتقاد الخدمة.'),
          TourAction('طلبات الأعضاء', 'حسابات مستنية الموافقة.'),
          TourAction('تايو الفصل', 'نقط الفصل القديمة، لو الفصل مفعّل.'),
          TourAction('المتجر', 'هدايا بنقط الفصل، لو المتجر مفعّل.'),
        ],
      ),
    'الأخبار' => const TourStep(
        title: 'الأخبار',
        summary: 'منشورات الفصل والتذكير.',
        actions: [],
      ),
    'التايو' => const TourStep(
        title: 'تايو الفصل',
        summary: 'نقط فصل الكنيسة. رصيد الخدمة في تبويب الرصيد، وكل واحد لوحده.',
        actions: [],
      ),
    'المتجر' => const TourStep(
        title: 'المتجر',
        summary: 'الهدايا بتتشترى من تايو الفصل.',
        actions: [
          TourAction('طلب الهدية', 'يخصم النقط بعد موافقة الخادم.'),
        ],
      ),
    'الرصيد' => TourStep(
        title: 'الرصيد',
        summary: 'رصيد الخدمة: المتاح، المصروف، والمكتسب.',
        actions: [
          if (role == null || role == 'makhdoum')
            const TourAction('رمز الحضور', 'يفضل ظاهر من غير نت. الخادم يمسحه من تبويب الحضور.'),
          if (role == 'amin') ...const [
            TourAction('تنفيذ الترحيل', 'يبقي حد الترحيل، والزيادة تنتهي.'),
            TourAction('معاينة نقل الفصول', 'تعرض نقل السنة قبل التنفيذ.'),
            TourAction('تنفيذ نقل الفصول', 'ينقل الأولاد بعد ما تكتب السنة.'),
          ],
          const TourAction('حذف بيانات الخدمة', 'يمسح بياناتك في الخدمة بعد جملة التأكيد.'),
          const TourAction('حذف الحساب', 'يقفل الحساب بعد جملة التأكيد.'),
        ],
      ),
    'السجل' => TourStep(
        title: 'السجل',
        summary: 'كل حركة نقط: الحضور، البنود، الرحلات، والسحب.',
        actions: [
          if (role == 'amin')
            const TourAction('تصحيح عكسي', 'يسجل حركة عكسية. الحركة الأصلية تفضل في السجل.'),
        ],
      ),
    'المسابقة' => TourStep(
        title: 'المسابقة',
        summary: publisher
            ? 'تنزل المسابقة وتعدّلها. التصحيح يتم لوحده، والنقط تتسجل من تبويب النقاط.'
            : 'تحل المسابقة في وقتها. التصحيح يتم لوحده.',
        actions: publisher
            ? const [
                TourAction('مسابقة جديدة', 'تبدأ أسئلة جديدة.'),
                TourAction('إضافة سؤال', 'سؤال اختيار من متعدد، والإجابة الصحيحة من الاختيارات.'),
                TourAction('نزل المسابقة', 'تنشرها للأولاد.'),
                TourAction('حفظ التعديل', 'يحفظ السؤال بعد النشر.'),
                TourAction('حذف المسابقة', 'يشيلها بعد التأكيد.'),
              ]
            : const [
                TourAction('سلّم المسابقة', 'يبعت إجاباتك وتتشاف النتيجة.'),
              ],
      ),
    'الاجتماع' => const TourStep(
        title: 'الاجتماع',
        summary: 'حضور الخدمة: عشية، اجتماع، أو قداس. المسح يسجل الوقت لوحده، مرة واحدة لكل ولد في اليوم.',
        actions: [
          TourAction('مسح الرمز', 'يقرأ رمز الولد ويسجل حضوره.'),
          TourAction('تسجيل يدوي', 'لو الولد نسي الموبايل. لازم سبب.'),
        ],
      ),
    'الافتقاد' => const TourStep(
        title: 'الافتقاد',
        summary: 'متابعة غياب أولاد فصلك.',
        actions: [
          TourAction('إعفاء من 25%', 'الولد يحجز الرحلة من غير ربع السعر من التوكن.'),
          TourAction('تم الافتقاد', 'يسجل الملاحظة على الولد المختار.'),
        ],
      ),
    'الترتيب' => const TourStep(
        title: 'الترتيب',
        summary: 'ترتيب الأولاد في الخدمة حسب الرصيد.',
        actions: [],
      ),
    'النقاط' => const TourStep(
        title: 'النقاط',
        summary: 'تسجيل بند تقييم. البند المكتوب عليه النظام يتسجل لوحده.',
        actions: [
          TourAction('تسجيل البند', 'بعد اختيار البند والفصل والولد.'),
        ],
      ),
    'الرحلات' => TourStep(
        title: 'الرحلات',
        summary: servant
            ? 'خادم الفصل يختار الأولاد ويحجز لهم. الولد لا يحجز لنفسه.'
            : 'تشوف حجزك، الباقي كاش، وتقدر تلغي حجزك.',
        actions: servant
            ? const [
                TourAction('حجز الرحلة', 'يحجز الأولاد المتعلمين. غير المعفي يدفع 25% من التوكن.'),
                TourAction('حضور بالرمز', 'يسجل حضور المؤتمر ويمنح نقطته.'),
                TourAction('الكاش اتدفع', 'يعلّم إن الباقي اتدفع.'),
                TourAction('إلغاء', 'يلغي حجز الولد حسب جدول الاسترداد.'),
              ]
            : const [
                TourAction('إلغاء', 'يلغي حجزك حسب ميعاد الاسترداد.'),
              ],
      ),
    'السحب' => TourStep(
        title: 'السحب',
        summary: role == 'amin'
            ? 'طلبات كاش الأولاد. النقط تتحجز وقت الطلب وترجع لو الطلب اترفض.'
            : 'طلب كاش من الرصيد. الرحلات تتخصم من تبويب الرحلات.',
        actions: role == 'amin'
            ? const [
                TourAction('موافقة', 'تعتمد الطلب.'),
                TourAction('رفض', 'ترجع النقط للولد.'),
              ]
            : const [
                TourAction('طلب سحب', 'يرسل الطلب للأمين.'),
              ],
      ),
    'الميزانية' => const TourStep(
        title: 'الميزانية',
        summary: 'المصروف، السقف، وتوقع نهاية السنة.',
        actions: [
          TourAction('إيقاف السحب', 'يوقف الكاش. الرحلات تفضل تتصرف بالنقط.'),
          TourAction('تشغيل السحب', 'يرجع طلبات الكاش.'),
          TourAction('حفظ الإعدادات', 'يحفظ أرقام الخدمة من نفس الصفحة.'),
        ],
      ),
    _ => TourStep(title: label, summary: 'هذا التبويب من حسابك.', actions: const []),
  };
}
