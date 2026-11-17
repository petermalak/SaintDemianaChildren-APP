class GuideTopic {
  final String title;
  final String summary;
  final List<String> steps;
  final String? boundary;

  const GuideTopic({
    required this.title,
    required this.summary,
    required this.steps,
    this.boundary,
  });
}

class GuideRequest {
  final bool staff;
  final bool makhdoumView;
  final bool hasScoring;
  final bool hasShop;
  final bool superAdmin;
  final bool canSwitch;
  final String? programRole;
  final List<String> programTabs;

  const GuideRequest({
    required this.staff,
    required this.makhdoumView,
    required this.hasScoring,
    required this.hasShop,
    required this.superAdmin,
    required this.canSwitch,
    required this.programRole,
    required this.programTabs,
  });
}

class AppGuide {
  static List<GuideTopic> topics(GuideRequest request) {
    final topics = <GuideTopic>[
      _role(request),
      _account(request),
    ];
    if (request.makhdoumView || !request.staff) {
      topics.add(_churchHome(member: true, service: request.programRole == 'makhdoum'));
      topics.add(_churchAttendance(member: true));
      topics.add(_news(member: true));
      if (request.hasScoring) topics.add(_classPoints(member: true));
      if (request.hasShop) topics.add(_shop(member: true));
    } else {
      topics.add(_churchHome(member: false));
      topics.add(_members());
      topics.add(_churchAttendance(member: false));
      topics.add(_more());
      topics.add(_news(member: false));
      topics.add(_churchFollowUp());
      topics.add(_memberRequests());
      if (request.hasScoring) topics.add(_classPoints(member: false));
      if (request.hasShop) topics.add(_shop(member: false));
      if (request.superAdmin) topics.add(_superAdmin());
    }
    for (final label in request.programTabs) {
      final topic = _program(label, request.programRole);
      if (topic != null) topics.add(topic);
    }
    return topics;
  }

  static GuideTopic _role(GuideRequest request) {
    final role = request.programRole;
    if (role == 'amin' || role == 'class' || role == 'score' || role == 'makhdoum') {
      return GuideTopic(
        title: 'دورك في الخدمة',
        summary: switch (role) {
          'amin' => 'أمين الخدمة يشوف كل فصول الخدمة، وكل صلاحية تحت دوره.',
          'class' => 'خادم الفصل شغله على أولاد فصله.',
          'score' => 'خادم السكور يسجّل بنود النقاط وينزل المسابقة.',
          _ => 'المخدوم يشوف رصيده ورمزه ومسابقته ورحلاته.',
        },
        steps: switch (role) {
          'amin' => const [
            'من الرصيد تشوف الصندوق، تنفّذ الترحيل، وتعاين نقل الفصول.',
            'من السحب تراجع طلبات الأولاد: موافقة أو رفض.',
            'من الميزانية تشوف المصروف والسقف، وتقدر توقف السحب الكاش.',
            'من الرحلات تحجز لأي مخدوم في الخدمة.',
            'من السجل تقدر تعمل تصحيح عكسي لحركة غلط.',
          ],
          'class' => const [
            'من الاجتماع تفتح اللقاء، تسجّل الحضور، وتقفل اللقاء.',
            'من النقاط تسجّل بنود أولاد فصلك.',
            'من الافتقاد تتابع الغياب، وتعفي ولد من شرط الـ 25% للرحلة.',
            'من الرحلات تختار أولاد فصلك وتحجز لهم.',
          ],
          'score' => const [
            'من النقاط اختَر البند والولد وسجّل النقط.',
            'من المسابقة تنزل الأسئلة وتعدّلها. التصحيح بيتم لوحده.',
            'نقط المسابقة مش بتتضاف لوحدها. سجّلها من بند المسابقة.',
          ],
          _ => const [
            'من الرئيسية أظهر رمز الحضور لخادم الفصل. الرمز يفضل ظاهر حتى لو النت قاطع.',
            'من المسابقة حلها في وقتها. الإجابة بتتصحح لوحدها.',
            'من الرحلات شوف حجزك، والباقي كاش، وتقدر تلغي حجزك.',
            'من السحب اطلب الكاش بعد الرحلات.',
          ],
        },
        boundary: switch (role) {
          'amin' => 'تبويب مخفي من الإدارة يختفي بعد ما تفتح الحساب من جديد.',
          'class' => 'مراجعة السحب والميزانية عند أمين الخدمة. طلب سحبك الشخصي من حساب المخدوم لو أنت مخدوم كمان.',
          'score' => 'الاجتماع والرحلات والسحب مش من شغلك. بند مكتوب عليه النظام بيتسجل لوحده.',
          _ => 'مش بتحجز الرحلة لنفسك، ومش بتسجّل حضور غيرك. خادم الفصل هو اللي يحجز ويعفي.',
        },
      );
    }
    if (request.superAdmin && request.staff) {
      return const GuideTopic(
        title: 'دورك',
        summary: 'مدير عام الكنيسة. ده غير أمين الخدمة.',
        steps: [
          'لوحة الخادم فيها الأعضاء والحضور والمزيد.',
          'من صورة الحساب فوق تفتح لوحة التحكم ونظام تايو الفصل.',
          'لو حسابك كمان مخدوم أو خادم فصل، بدّل الحساب من صورة الحساب.',
        ],
        boundary: 'إدارة طايو الخدمة من أداة الإدارة، مش من شاشة المخدوم.',
      );
    }
    if (request.staff && !request.makhdoumView) {
      return const GuideTopic(
        title: 'دورك',
        summary: 'خادم الفصل في الكنيسة.',
        steps: [
          'الرئيسية والأعضاء والحضور لفصل الكنيسة.',
          'المزيد فيه الأخبار والافتقاد وطلبات الأعضاء.',
          'تايو الفصل والمتجر يظهروا لو الفصل مفعّل لهم.',
        ],
        boundary: 'طايو الخدمة، لو ظاهر، غير تايو الفصل. كل واحد له رصيد لوحده.',
      );
    }
    return const GuideTopic(
      title: 'دورك',
      summary: 'مخدوم الفصل.',
      steps: [
        'شوف حضورك وأخبار الفصل.',
        'تايو الفصل هو نقط الفصل القديمة، لو التبويب ظاهر.',
        'المتجر يشتري بهدايا من نقط الفصل، لو التبويب ظاهر.',
      ],
      boundary: 'مش بتعدّل حضور غيرك ومش بتشوف ترتيب الخدمة.',
    );
  }

  static GuideTopic _account(GuideRequest request) {
    return GuideTopic(
      title: 'حسابك',
      summary: 'الدليل ده موجود دايمًا من علامة الاستفهام فوق.',
      steps: [
        'اضغط علامة الاستفهام في أي وقت وافتح الموضوع اللي محتاجه.',
        'من صورة الحساب تفتح الملف الشخصي وتسجّل خروج.',
        if (request.canSwitch) 'لو عندك أكتر من فصل أو دور، بدّل الحساب من صورة الحساب.',
        if (request.programRole != null) 'حذف بيانات الخدمة أو حذف الحساب من آخر صفحة الرصيد، وبكلمة التأكيد المكتوبة.',
      ],
      boundary: request.programRole == null ? null : 'حذف الحساب يقفل الدخول. حضور الكنيسة القديم مش بيتمسح.',
    );
  }

  static GuideTopic _churchHome({required bool member, bool service = false}) {
    return GuideTopic(
      title: 'الرئيسية',
      summary: service
          ? 'رمز حضورك ظاهر هنا، والخادم يمسحه من الحضور.'
          : member
              ? 'ملخص فصلك في الكنيسة.'
              : 'ملخص فصل الكنيسة اللي أنت خادمه.',
      steps: service
          ? const [
              'أظهر رمز الحضور لخادم الفصل.',
              'أول ما الرمز يظهر والنت موجود، يفضل ظاهر حتى لو النت قاطع.',
            ]
          : member
              ? const ['افتح الرئيسية عشان تشوف أخبار اليوم والاختصارات.', 'التبويبات تحت هي اللي تقدر تستخدمها.']
              : const ['افتح الرئيسية عشان تشوف فصل الكنيسة.', 'الأزرار السريعة بتوديك للحضور والأعضاء.'],
    );
  }

  static GuideTopic _members() {
    return const GuideTopic(
      title: 'الأعضاء',
      summary: 'أولاد فصل الكنيسة.',
      steps: [
        'دور على الولد بالاسم.',
        'من الولد تسجّل حضور أو تطلب إضافة عضو.',
      ],
      boundary: 'أعضاء خدمة طايو مش بيظهروا هنا كفصل كنيسة قديم.',
    );
  }

  static GuideTopic _churchAttendance({required bool member}) {
    return GuideTopic(
      title: 'حضور الكنيسة',
      summary: member ? 'حضور القداس والاجتماع بتاع فصلك.' : 'تسجيل حضور فصل الكنيسة.',
      steps: member
          ? const ['افتح تبويب الحضور وشوف الأيام اللي اتسجّلت.']
          : const ['افتح الحضور واختَر الاجتماع.', 'سجّل الحاضرين. ده حضور الكنيسة، مش اجتماع طايو.'],
      boundary: 'اجتماع طايو له تبويب باسم الاجتماع، ورمزه غير حضور الكنيسة.',
    );
  }

  static GuideTopic _more() {
    return const GuideTopic(
      title: 'المزيد',
      summary: 'باقي أدوات فصل الكنيسة في مكان واحد.',
      steps: [
        'افتح المزيد.',
        'اختَر الأخبار أو الافتقاد أو طلبات الأعضاء.',
        'تايو الفصل والمتجر يظهروا هنا لو الفصل مفعّل لهم.',
      ],
    );
  }

  static GuideTopic _news({required bool member}) {
    return GuideTopic(
      title: 'الأخبار',
      summary: 'إعلانات الفصل.',
      steps: member
          ? const ['اقرأ المنشورات من تبويب الأخبار.']
          : const ['من المزيد افتح الأخبار.', 'اقرأ إعلانات الفصل.'],
    );
  }

  static GuideTopic _churchFollowUp() {
    return const GuideTopic(
      title: 'افتقاد الكنيسة',
      summary: 'متابعة أولاد فصل الكنيسة.',
      steps: [
        'من المزيد افتح الافتقاد.',
        'سجّل الزيارة وعلّمها تمت.',
      ],
      boundary: 'افتقاد طايو من تبويب الافتقاد في الخدمة، وفيه إعفاء الرحلة.',
    );
  }

  static GuideTopic _memberRequests() {
    return const GuideTopic(
      title: 'طلبات الأعضاء',
      summary: 'طلبات الانضمام لفصل الكنيسة.',
      steps: ['من المزيد افتح طلبات الأعضاء.', 'اقبل الطلب أو ارفضه.'],
    );
  }

  static GuideTopic _classPoints({required bool member}) {
    return GuideTopic(
      title: 'تايو الفصل',
      summary: 'نقط فصل الكنيسة القديمة. دي غير توكن الخدمة.',
      steps: member
          ? const ['افتح تبويب التايو وشوف نقط الفصل.', 'الهدايا بتتشترى من المتجر بالنقط دي.']
          : const ['من المزيد افتح التايو.', 'سجّل نقط الفصل حسب البنود الظاهرة.'],
      boundary: 'رصيد طايو الخدمة في تبويب الرصيد، ومش بينتقل لتايو الفصل.',
    );
  }

  static GuideTopic _shop({required bool member}) {
    return GuideTopic(
      title: 'المتجر',
      summary: member ? 'هدايا بنقط تايو الفصل.' : 'طلبات شراء أولاد الفصل.',
      steps: member
          ? const ['افتح المتجر واختَر الهدية.', 'الطلب يستنى موافقة الخادم.']
          : const ['من المزيد افتح المتجر.', 'وافق على الطلب أو ارفضه.'],
      boundary: 'المتجر بيصرف نقط تايو الفصل، مش توكن الخدمة.',
    );
  }

  static GuideTopic _superAdmin() {
    return const GuideTopic(
      title: 'إدارة الكنيسة',
      summary: 'أدوات المدير العام من صورة الحساب.',
      steps: [
        'لوحة التحكم فيها الفصول والأعضاء.',
        'نظام التايو العام يعدّل بنود تايو الفصل.',
        'طايو الخدمة وأرقامه من صفحة طايو في أداة الإدارة.',
      ],
      boundary: 'مدير عام الكنيسة مش هو أمين الخدمة إلا لو الدور ده متعيّن له.',
    );
  }

  static GuideTopic? _program(String label, String? role) {
    final amin = role == 'amin';
    final servant = role == 'class' || amin;
    final keeper = role == 'score' || servant;
    return switch (label) {
      'الرصيد' => GuideTopic(
          title: 'الرصيد',
          summary: 'توكن الخدمة: المتاح، والمصروف، والمكتسب.',
          steps: [
            if (role == null || role == 'makhdoum') 'أظهر رمز الحضور لخادم الفصل. الرمز يفضل ظاهر من غير نت.',
            'السلسلة والمستوى يظهروا لو الإدارة مفعّلاهم.',
            if (amin) 'تنفيذ الترحيل ينقل الحد المسموح للسنة الجديدة والباقي ينتهي.',
            if (amin) 'اكتب السنة الخدمية، عاين نقل الفصول، وبعدين نفّذه.',
          ],
          boundary: amin ? null : 'الترحيل ونقل الفصول عند أمين الخدمة.',
        ),
      'السجل' => GuideTopic(
          title: 'السجل',
          summary: 'كل حركة نقط: مين سجّلها، وامتى، وبأي بند.',
          steps: [
            'اقرأ الحركة من الأحدث.',
            if (amin) 'لو الحركة غلط، اضغط تصحيح عكسي. التصحيح بيضيف حركة جديدة ومش بيمسح القديمة.',
          ],
          boundary: amin ? 'مش تقدر تعكس تصحيحًا اتعمل قبل كده.' : 'تصحيح السجل عند أمين الخدمة.',
        ),
      'المسابقة' => GuideTopic(
          title: 'المسابقة',
          summary: keeper ? 'مسابقة باختيارات، والتصحيح تلقائي.' : 'حل المسابقة في وقت فتحها.',
          steps: keeper
              ? const [
                  'اكتب اسم المسابقة ووقت فتحها.',
                  'لكل سؤال اكتب الاختيارات وعلّم الإجابة الصح.',
                  'الأولاد يحلّوا، والنتيجة تظهر لوحدها.',
                ]
              : const [
                  'استنى وقت الفتح.',
                  'اختَر إجابة واحدة لكل سؤال وابعت.',
                  'النتيجة تظهر بعد الإرسال.',
                ],
          boundary: keeper
              ? 'تعديل الأسئلة يمسح إجابات الأولاد. نقط المسابقة تتسجّل من تبويب النقاط.'
              : 'مش بتقدر تنزل المسابقة ولا تشوف الإجابة الصح قبل الحل.',
        ),
      'السحب' => GuideTopic(
          title: 'السحب',
          summary: amin ? 'مراجعة طلبات تحويل النقط لكاش.' : 'طلب تحويل النقط لكاش.',
          steps: amin
              ? const ['اقرأ الطلب من الأقدم.', 'وافق أو ارفض. الرفض يرجّع النقط.']
              : const [
                  'اتأكد إن الرحلات اتخصمت الأول.',
                  'اكتب عدد النقط وابعت الطلب.',
                  'النقط بتتحجز لحد ما أمين الخدمة يرد.',
                ],
          boundary: amin
              ? 'لو السحب واقف، الموافقة تقف. الرحلات تفضل تتصرف.'
              : 'خادم الفصل وخادم السكور مش بيطلبوا سحب من حساب الخدمة. الطلب من حساب المخدوم.',
        ),
      'الاجتماع' => const GuideTopic(
          title: 'الاجتماع',
          summary: 'حضور لقاء الخدمة. التسجيل من غير فتح وقت.',
          steps: [
            'اختَر الفصل ونوع الحضور: عشية، اجتماع، أو قداس.',
            'امسح رمز المخدوم، أو سجّل يدوي واكتب السبب.',
          ],
          boundary: 'خادم السكور والمخدوم مش بيسجلوا الحضور. كل مخدوم مرة واحدة في اليوم لنفس النوع.',
        ),
      'الافتقاد' => const GuideTopic(
          title: 'افتقاد الخدمة',
          summary: 'متابعة أولاد فصلك في طايو.',
          steps: [
            'شوف آخر حضور وعدد أسابيع الغياب.',
            'علّم إن الافتقاد تم.',
            'التكة تعفي الولد من دفع 25% من الرحلة بالنقط.',
          ],
          boundary: 'الإعفاء لأولاد فصلك فقط، والرحلة لسه محتاجة حجز منك أو من الأمين.',
        ),
      'الترتيب' => const GuideTopic(
          title: 'الترتيب',
          summary: 'متوسط كل فصل وأولاده.',
          steps: ['افتح الترتيب.', 'الفصول متترتبة بالمتوسط، والأولاد بالنقط.'],
          boundary: 'المخدوم مش بيشوف الترتيب.',
        ),
      'النقاط' => GuideTopic(
          title: 'النقاط',
          summary: 'تسجيل بند على مخدوم.',
          steps: const [
            'اختَر البند، وبعدين الولد.',
            'البند الظاهر هو اللي تقدر تسجّله.',
            'السقف بتاع البند يمنع الزيادة عن العدد المسموح.',
          ],
          boundary: servant
              ? 'بند النظام بيتسجل لوحده ومش يتسجّل بإيدك.'
              : 'تسجّل بنود خادم السكور فقط، وعلى مخدوم داخل الخدمة. الاجتماع والرحلات مش من صلاحيتك.',
        ),
      'الميزانية' => const GuideTopic(
          title: 'الميزانية',
          summary: 'صندوق الخدمة للأمين.',
          steps: [
            'شوف المتوقع والمصروف والسقف والباقي.',
            'إيقاف السحب الكاش يمنع الطلبات الجديدة.',
            'من هنا كمان التقرير والخادم والقيم.',
          ],
          boundary: 'الرحلات تفضل تتصرف بالنقط حتى لو السحب واقف.',
        ),
      'الرحلات' => GuideTopic(
          title: 'الرحلات',
          summary: servant ? 'الحجز للأولاد، مش الولد يحجز لنفسه.' : 'حالة حجزك والباقي عليك.',
          steps: servant
              ? const [
                  'اختَر الرحلة والأولاد.',
                  'جزء من السعر لازم يتدفع من التوكن، إلا لو الولد متعفي.',
                  'علّم الكاش لما يتدفع، والحضور لما يحضر.',
                ]
              : const [
                  'شوف الرحلة، النقط المدفوعة، والباقي كاش.',
                  'لو في قائمة انتظار هتشوفها.',
                  'تقدر تلغي حجزك، ونسبة الاسترداد حسب ميعاد الإلغاء.',
                ],
          boundary: servant
              ? 'خادم الفصل يحجز لأولاد فصله. الأمين يحجز لأي مخدوم في الخدمة.'
              : 'الحجز نفسه من خادم الفصل أو الأمين.',
        ),
      _ => null,
    };
  }
}
