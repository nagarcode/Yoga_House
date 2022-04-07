import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Client/health_assurance.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';

class HealthAssuranceScreen extends StatefulWidget {
  final UserInfo userInfo;
  final FirestoreDatabase database;

  static Future<void> pushToTabBar(
      BuildContext context, UserInfo userInfo) async {
    final database = context.read<FirestoreDatabase>();
    await pushNewScreen(
      context,
      screen: HealthAssuranceScreen(
        database: database,
        userInfo: userInfo,
      ),
    );
  }

  const HealthAssuranceScreen(
      {Key? key, required this.userInfo, required this.database})
      : super(key: key);

  @override
  _HealthAssuranceScreenState createState() => _HealthAssuranceScreenState();
}

class _HealthAssuranceScreenState extends State<HealthAssuranceScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  late bool _isLoading;
  late bool bloodPressure;
  late bool diabetes;
  late bool headachesDizzinessWeakness;
  late bool astma;
  late bool balance;
  late bool neck;
  late bool wrist;
  late bool spine;
  late bool digestion;
  late bool ears;
  late bool eyes;
  late bool chronicStuff;
  late bool surgery;
  late bool smoking;
  late bool calcium;
  late bool pregnant;
  late bool pregnantStuff;
  late int? numOfBirths;
  late bool periodProblems;
  late String notes;
  late String name;
  late String phone;
  late String address;
  late int? age;
  late String email;
  late bool showForm;
  DateTime date = DateTime.now();

  String get _firstLine =>
      'יש ליידע את המורה ביחס למצבים הנ"ל על מנת להתאים אימון טוב יותר, וכדי לבחון האם יש צורך באישור או בהמלצת רופא להשתתפותך בשיעורים.';
  String get _secondLine =>
      'בחתימתך על הצהרת בריאות זו, הנך מאשר/ת כי נבדקת ע"י רופא שאישר את השתתפותך בשיעורי היוגה וכי את מודעת לכך שכל מידע, ייעוץ והכוונה הניתנים במסגרת שעורי היוגה או הטיפולים האלטרנטיביים, אינם מהווים תחליף לטיפול רפואי ו/או התייעצות עם גורם רפואי מוסמך וכי אין בכוונתך להפסיק טיפול תרופתי או טיפול רפואי אחר, ללא התייעצות עם רופא. ';
  String get _thirdLine =>
      'הנני מצהיר/ה כי ברור לי שכל הפרטים הנ"ל חיוניים לצורך סוג ומהות הטיפול/תרגול ועניתי לשאלות ביושר ובתום לב.';
  String get _fourthLine =>
      'אני מצהיר/ה שהתרגול הוא על אחריותי האישית וכי אציית לנוהלי השיעור.';

  @override
  void initState() {
    _initHAFields();
    name = widget.userInfo.name;
    phone = Utils.stripPhonePrefix(widget.userInfo.phoneNumber);
    email = widget.userInfo.email;
    showForm = !widget.userInfo.didSubmitHealthAssurance;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Utils.appBarTitle(context, 'הצהרת בריאות'),
      ),
      body: showForm
          ? FormBuilder(
              autoFocusOnValidationFailure: true,
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: _questions(),
                ),
              ),
            )
          : _hasHealthAssuranceButton(),
    );
  }

  List<Widget> _questions() {
    final theme = Theme.of(context);

    return [
      _prefix(),
      FormBuilderCheckbox(
        name: 'blood',
        initialValue: bloodPressure,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            bloodPressure = newVal;
          });
        },
        title: const Text('לחץ דם'),
      ),
      FormBuilderCheckbox(
        name: 'diabetes',
        initialValue: diabetes,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            diabetes = newVal;
          });
        },
        title: const Text('סוכרת'),
      ),
      FormBuilderCheckbox(
        name: 'headaches',
        initialValue: headachesDizzinessWeakness,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            headachesDizzinessWeakness = newVal;
          });
        },
        title: const Text('כאבי ראש, סחרחורות, חולשה'),
      ),
      FormBuilderCheckbox(
        name: 'astma',
        initialValue: astma,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            astma = newVal;
          });
        },
        title: const Text('אסטמה או בעיות נשימה'),
      ),
      FormBuilderCheckbox(
        name: 'balance',
        initialValue: balance,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            balance = newVal;
          });
        },
        title: const Text('בעיות שיווי משקל'),
      ),
      FormBuilderCheckbox(
        name: 'neck',
        initialValue: neck,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            neck = newVal;
          });
        },
        title: const Text('בעיות צוואר, עורף או כתפיים'),
      ),
      FormBuilderCheckbox(
        name: 'wrists',
        initialValue: wrist,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            wrist = newVal;
          });
        },
        title: const Text('בעיות במפרקים'),
      ),
      FormBuilderCheckbox(
        name: 'spine',
        initialValue: spine,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            spine = newVal;
          });
        },
        title: const Text('בעיות בעמוד השדרה(פריצת דיסק, עקמת וכדומה)'),
      ),
      FormBuilderCheckbox(
        name: 'digestion',
        initialValue: digestion,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            digestion = newVal;
          });
        },
        title: const Text('בעיות עיכול'),
      ),
      FormBuilderCheckbox(
        name: 'ears',
        initialValue: ears,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            ears = newVal;
          });
        },
        title: const Text('בעיות אוזניים'),
      ),
      FormBuilderCheckbox(
        name: 'glaucoma',
        initialValue: eyes,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            eyes = newVal;
          });
        },
        title: const Text('גלאוקומה או בעיות עיניים אחרות'),
      ),
      FormBuilderCheckbox(
        name: 'chronic',
        initialValue: chronicStuff,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            chronicStuff = newVal;
          });
        },
        title: const Text('מחלה כרוננית כלשהי (פעילה או רדומה)'),
      ),
      FormBuilderCheckbox(
        name: 'surgery',
        initialValue: surgery,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            surgery = newVal;
          });
        },
        title: const Text('ניתוחים כירורגיים'),
      ),
      FormBuilderCheckbox(
        name: 'smoke',
        initialValue: smoking,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            smoking = newVal;
          });
        },
        title: const Text('מעשן?'),
      ),
      FormBuilderCheckbox(
        name: 'calcium',
        initialValue: calcium,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            calcium = newVal;
          });
        },
        title: const Text('בריחת סידן/אוסטאופורוזיס'),
      ),
      // Text(
      //   'לנשים:',
      //   style: theme.textTheme.bodyText1?.copyWith(color: Colors.black),
      // ),
      FormBuilderCheckbox(
        name: 'pregs',
        initialValue: pregnant,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            pregnant = newVal;
          });
        },
        title: const Text('האם את בהריון?'),
      ),
      FormBuilderCheckbox(
        name: 'preggs stuff',
        initialValue: pregnantStuff,
        onChanged: (newVal) {
          setState(() {
            if (newVal == null) return;
            pregnantStuff = newVal;
          });
        },
        title: const Text(
            'במידה וכן האם את סובלת מ: לחץ דם גבוה/נמוך, דופק מואץ, סכרת הריונית, אי ספיקת צוואר רחם, סימפיזיולוזיס?'),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7.0),
        child: FormBuilderTextField(
          name: 'births',
          initialValue: numOfBirths?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'כמה לידות עברת?',
          ),
          onChanged: (newVal) {
            if (newVal == null) return;
            numOfBirths = int.tryParse(newVal);
          },
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.numeric(context),
            FormBuilderValidators.max(context, 10),
            FormBuilderValidators.required(context),
          ]),
          keyboardType: TextInputType.number,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7.0),
        child: Text(
          '**נשים בזמן וסת או הריון צריכות להימנע מתרגילים מסוימים. אנא היוועצי עם המורה לפני תחילת השיעור',
          style: theme.textTheme.bodyText1,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7.0),
        child: FormBuilderTextField(
          name: 'notes',
          initialValue: notes,
          decoration: const InputDecoration(
            labelText: 'הערות?',
          ),
          onChanged: (newVal) {
            if (newVal == null) return;
            notes = newVal;
          },
          validator: FormBuilderValidators.compose(
              [FormBuilderValidators.maxLength(context, 50)]),
        ),
      ),
      _suffix(),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7.0),
        child: FormBuilderTextField(
          initialValue: name,
          name: 'name',
          decoration: const InputDecoration(
            labelText: 'שם מלא',
          ),
          onChanged: (newVal) {
            if (newVal == null) return;
            name = newVal;
          },
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.maxLength(context, 50),
            FormBuilderValidators.required(context),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7.0),
        child: FormBuilderTextField(
          name: 'phone',
          initialValue: phone,
          decoration: const InputDecoration(
            labelText: 'טלפון',
          ),
          onChanged: (newVal) {
            if (newVal == null) return;
            phone = newVal;
          },
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.maxLength(context, 50),
            FormBuilderValidators.required(context),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7.0),
        child: FormBuilderTextField(
          name: 'address',
          decoration: const InputDecoration(
            labelText: 'כתובת',
          ),
          initialValue: address,
          onChanged: (newVal) {
            if (newVal == null) return;
            address = newVal;
          },
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.maxLength(context, 50),
            FormBuilderValidators.required(context),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7.0),
        child: FormBuilderTextField(
          name: 'age',
          initialValue: age?.toString(),
          decoration: const InputDecoration(
            labelText: 'גיל',
          ),
          onChanged: (newVal) {
            if (newVal == null) return;
            age = int.tryParse(newVal);
          },
          validator: FormBuilderValidators.compose(
            [
              FormBuilderValidators.maxLength(context, 2),
              FormBuilderValidators.numeric(context),
              FormBuilderValidators.required(context),
            ],
          ),
          keyboardType: TextInputType.number,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7.0),
        child: FormBuilderTextField(
          name: 'email',
          initialValue: email,
          decoration: const InputDecoration(
            labelText: 'אימייל',
          ),
          onChanged: (newVal) {
            if (newVal == null) return;
            email = newVal;
          },
          validator: FormBuilderValidators.compose(
            [
              FormBuilderValidators.maxLength(context, 50),
              FormBuilderValidators.required(context),
            ],
          ),
        ),
      ),
      _submitButton(),
      const SizedBox(height: 30),
    ];
  }

  Widget _submitButton() {
    return ElevatedButton(
        onPressed: _isLoading
            ? null
            : () async {
                _setIsLoading(true);
                if (_formKey.currentState!.validate()) {
                  final numOfBirths = this.numOfBirths;
                  final age = this.age;
                  if (numOfBirths == null || age == null) return;
                  final healthAssurance = HealthAssurance(
                      bloodPressure: bloodPressure,
                      diabetes: diabetes,
                      headachesDizzinessWeakness: headachesDizzinessWeakness,
                      astma: astma,
                      balance: balance,
                      neck: neck,
                      wrist: wrist,
                      spine: spine,
                      digestion: digestion,
                      ears: ears,
                      eyes: eyes,
                      chronicStuff: chronicStuff,
                      surgery: surgery,
                      smoking: smoking,
                      calcium: calcium,
                      pregnant: pregnant,
                      pregnantStuff: pregnantStuff,
                      numOfBirths: numOfBirths,
                      periodProblems: periodProblems,
                      notes: notes,
                      name: name,
                      phone: phone,
                      address: address,
                      age: age,
                      email: email,
                      date: date);
                  await widget.database
                      .setHealthAssurance(widget.userInfo, healthAssurance);
                } else {
                  _setIsLoading(false);
                }
              },
        child: const Text('שלח'));
  }

  Widget _suffix() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        '$_firstLine\n$_secondLine\n$_thirdLine\n$_fourthLine',
        style: theme.textTheme.bodyText1,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _prefix() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        "יוגה היא שיטת אימון המתאימה לכל גיל ולכל רמה של כוח, כושר וגמישות. אולם, קיימים מספר מצבים רפואיים הדורשים אימון מעט שונה ותשומת לב מיוחדת מצד המורה והמתרגל.אנא ידע/י את המורה בהיסטוריה הרפואית הבסיסית שלך. סמן V היכן שקיימת בעיה בהווה או הייתה קיימת בעבר:",
        style: theme.textTheme.bodyText1,
        // style: theme.textTheme.bodyText1?.copyWith(fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _setIsLoading(bool newVal) {
    setState(() {
      _isLoading = newVal;
    });
  }

  void _setShowForm(bool newVal) {
    setState(() {
      showForm = newVal;
    });
  }

  Widget _hasHealthAssuranceButton() {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 15),
        Center(
            child: Text(
          'הגשת הצהרת בריאות בעבר. האם ברצונך להגיש אחת חדשה?',
          style: theme.textTheme.bodyText1,
        )),
        ElevatedButton(
            onPressed: () => _setShowForm(true),
            child: const Text('מלא הצהרה חדשה')),
      ],
    );
  }

  void _initHAFields() {
    final ha = widget.userInfo.healthAssurance;
    _isLoading = false;
    if (ha == null) {
      _initDefaultFields();
      return;
    }
    bloodPressure = ha.bloodPressure;
    diabetes = ha.diabetes;
    headachesDizzinessWeakness = ha.headachesDizzinessWeakness;
    astma = ha.astma;
    balance = ha.balance;
    neck = ha.neck;
    wrist = ha.wrist;
    spine = ha.spine;
    digestion = ha.digestion;
    ears = ha.ears;
    eyes = ha.eyes;
    chronicStuff = ha.chronicStuff;
    surgery = ha.surgery;
    smoking = ha.smoking;
    calcium = ha.calcium;
    pregnant = ha.pregnant;
    pregnantStuff = ha.pregnantStuff;
    numOfBirths = ha.numOfBirths;
    periodProblems = ha.periodProblems;
    notes = ha.notes;
    name = ha.name;
    phone = ha.phone;
    address = ha.address;
    age = ha.age;
    email = ha.email;
  }

  void _initDefaultFields() {
    bloodPressure = false;
    diabetes = false;
    headachesDizzinessWeakness = false;
    astma = false;
    balance = false;
    neck = false;
    wrist = false;
    spine = false;
    digestion = false;
    ears = false;
    eyes = false;
    chronicStuff = false;
    surgery = false;
    smoking = false;
    calcium = false;
    pregnant = false;
    pregnantStuff = false;
    numOfBirths = null;
    periodProblems = false;
    notes = '';
    name = widget.userInfo.name;
    phone = widget.userInfo.phoneNumber;
    address = '';
    age = null;
    email = widget.userInfo.email;
  }
}
