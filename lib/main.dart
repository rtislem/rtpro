import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class RendezVous {
  final String time;
  final String description;
  final String date;

  RendezVous({
    required this.time,
    required this.description,
    required this.date,
  });

  factory RendezVous.fromJson(Map<String, dynamic> json) {
    return RendezVous(
      time: json['time'],
      description: json['description'],
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'description': description,
      'date': date,
    };
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    const AgendaTab(),
    const CompteurTab(),
    const ExplicationTab(),
    const NumeroUtileTab(),
  ];

  final List<String> _tabTitles = [
    'Gestion des Rendez-vous',
    'Compteur des Séances',
    'Explication de la Radiothérapie',
    'Retard',
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_currentIndex]),
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
            backgroundColor: Colors.blue.shade700,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Compteur',
            backgroundColor: Colors.green.shade700,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Explication',
            backgroundColor: Colors.orange.shade700,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_empty, color: Colors.black),
            label: 'Retard',
            backgroundColor: Colors.red.shade700,
          ),
        ],
      ),
    );
  }
}

class AgendaTab extends StatefulWidget {
  const AgendaTab({super.key});

  @override
  State<AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends State<AgendaTab> {
  late final ValueNotifier<List<RendezVous>> _selectedEvents;
  DateTime _selectedDay = DateTime.now();
  late TextEditingController _timeController;
  late String _selectedDescription;

  @override
  void initState() {
    super.initState();
    _selectedEvents = ValueNotifier([]);
    _timeController = TextEditingController();
    _selectedDescription = "Séance de radiothérapie"; // Valeur par défaut
    _loadEvents();
  }

  void _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEvents = prefs.getString('events') ?? '[]';
    final List<RendezVous> events = (jsonDecode(savedEvents) as List)
        .map((e) => RendezVous.fromJson(e))
        .toList();
    _selectedEvents.value = events;
  }

  void _addEvent() {
    if (_timeController.text.isNotEmpty) {
      final newEvent = RendezVous(
        time: _timeController.text,
        description: _selectedDescription,
        date: _selectedDay.toIso8601String().split('T')[0], // Sauvegarde uniquement la date (jour/mois/année)
      );

      final currentEvents = _selectedEvents.value;
      currentEvents.add(newEvent);
      _selectedEvents.value = List.from(currentEvents);

      _saveEvents(currentEvents); // Sauvegarder les événements dans SharedPreferences
      _timeController.clear();
    }
  }

  void _saveEvents(List<RendezVous> events) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = jsonEncode(events.map((e) => e.toJson()).toList());
    prefs.setString('events', eventsJson);
  }

  void _removeEvent(RendezVous event) async {
    final currentEvents = _selectedEvents.value;
    currentEvents.remove(event);
    _selectedEvents.value = List.from(currentEvents);

    _saveEvents(currentEvents); // Sauvegarder la nouvelle liste d'événements
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _selectedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orange.shade300,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue.shade300,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.blue.shade500,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: (day) {
              final eventsForDay = _selectedEvents.value
                  .where((event) => event.date == day.toIso8601String().split('T')[0])
                  .toList();
              return eventsForDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  final event = events.first as RendezVous;
                  if (event.description == 'Séance de radiothérapie') {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade500,
                        shape: BoxShape.circle,
                      ),
                    );
                  } else if (event.description == 'Médecin') {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        shape: BoxShape.circle,
                      ),
                    );
                  }
                }
                return const SizedBox();
              },
            ),
          ),
          ValueListenableBuilder<List<RendezVous>>(
            valueListenable: _selectedEvents,
            builder: (context, events, _) {
              final eventsForDay = events
                  .where((event) => event.date == _selectedDay.toIso8601String().split('T')[0])
                  .toList();
              return Expanded(
                child: ListView.builder(
                  itemCount: eventsForDay.length,
                  itemBuilder: (context, index) {
                    final event = eventsForDay[index];
                    return Dismissible(
                      key: Key(event.time),
                      onDismissed: (direction) {
                        _removeEvent(event);
                      },
                      background: Container(color: Colors.red),
                      child: ListTile(
                        title: Text(event.description),
                        subtitle: Text('Heure: ${event.time}'),
                        tileColor: event.description == 'Séance de radiothérapie'
                            ? Colors.blue.shade50
                            : event.description == 'Médecin'
                            ? Colors.green.shade50
                            : Colors.white,
                      ),
                    );
                  },
                ),
              );
            },
          ),
          TextField(
            controller: _timeController,
            decoration: const InputDecoration(labelText: 'Heure'),
          ),
          DropdownButton<String>(
            value: _selectedDescription,
            onChanged: (String? newValue) {
              setState(() {
                _selectedDescription = newValue!;
              });
            },
            items: <String>['Séance de radiothérapie', 'Médecin']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          ElevatedButton(
            onPressed: _addEvent,
            child: const Text('Ajouter un rendez-vous'),
          ),
        ],
      ),
    );
  }
}

class CompteurTab extends StatefulWidget {
  const CompteurTab({super.key});

  @override
  State<CompteurTab> createState() => _CompteurTabState();
}

class _CompteurTabState extends State<CompteurTab> {
  int totalSessions = 30; // Valeur initiale
  int completedSessions = 0;
  late TextEditingController _totalSessionsController;

  @override
  void initState() {
    super.initState();
    _totalSessionsController = TextEditingController(text: totalSessions.toString());
    _loadEvents();
  }

  void _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEvents = prefs.getString('events') ?? '[]';
    final List<RendezVous> events = (jsonDecode(savedEvents) as List)
        .map((e) => RendezVous.fromJson(e))
        .toList();

    setState(() {
      completedSessions = events
          .where((event) => event.description == 'Séance de radiothérapie')
          .length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _totalSessionsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nombre total de séances',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                totalSessions = int.tryParse(value) ?? totalSessions;
              });
            },
          ),
          const SizedBox(height: 10),
          Text('Séances effectuées: $completedSessions/$totalSessions'),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: completedSessions / totalSessions,
          ),
        ],
      ),
    );
  }
}

class ExplicationTab extends StatelessWidget {
  const ExplicationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qu\'est-ce que la radiothérapie ?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'La radiothérapie utilise des radiations à haute énergie pour détruire les cellules cancéreuses. '
                'Le traitement dure une dizaine de minutes. Il commence par une ou plusieurs images. La machine tournera autour de vous sans jamais vous toucher. Nous vous surveillons grâce à plusieurs caméras.',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 16),
          Text(
            'Conseils :',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            '- Ne jamais bouger pendant le traitement.\n'
                '- Pour un traitement de la protate : rectum vide vessie pleine.\n'
                '- Ne jamais appliquer de crème avant la séance sur la zone de traitement.\n'
                '- Si besoin un médecin d\'astreinte est disponible .\n',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class NumeroUtileTab extends StatelessWidget {
  const NumeroUtileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion des Retards',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Colors.blueAccent, // Couleur principale
          secondary: Colors.orange,   // Couleur secondaire
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(), // Page de connexion (accueil)
        '/patient': (context) => const PatientScreen(), // Ecran patient
        '/personnel': (context) => const PersonnelScreen(), // Ecran personnel
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final String _validUsername = 'personnel'; // Nom d'utilisateur valide
  final String _validPassword = 'motdepasse'; // Mot de passe valide

  String _errorMessage = ''; // Message d'erreur si la connexion échoue

  void _login() {
    // Vérification des informations d'identification
    if (_usernameController.text == _validUsername && _passwordController.text == _validPassword) {
      // Redirige vers l'écran personnel si l'authentification est correcte
      Navigator.pushReplacementNamed(context, '/personnel');
    } else {
      setState(() {
        _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Se connecter'),
        backgroundColor: Colors.blueAccent,
        leading: Container(), // Suppression du bouton retour
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nom d\'utilisateur',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _login,
              child: const Text(
                'Se connecter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white, // Changer la couleur du texte ici
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/patient');
              },
              child: const Text(
                'Mode Patient',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white, // Changer la couleur du texte ici
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientScreen extends StatelessWidget {
  const PatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etat des Retards'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/'); // Remplacer l'écran actuel par la page de connexion
          },
        ),
      ),
      body: Center(
        child: ValueListenableBuilder<int>(
          valueListenable: retardNotifier,
          builder: (context, retardLevel, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getRetardText(retardLevel),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildRetardIndicator(retardLevel),
              ],
            );
          },
        ),
      ),
    );
  }

  // Fonction pour obtenir le texte correspondant au niveau de retard
  String _getRetardText(int level) {
    if (level == 0) {
      return 'Pas de retard';
    } else if (level == 1) {
      return 'Léger retard';
    } else {
      return 'Retard conséquent';
    }
  }

  // Affichage du texte des niveaux de retard sans les icônes
  Widget _buildRetardIndicator(int level) {
    return Container(); // Pas d'icônes à afficher
  }
}

class PersonnelScreen extends StatefulWidget {
  const PersonnelScreen({super.key});

  @override
  _PersonnelScreenState createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends State<PersonnelScreen> {
  int _selectedLevel = 0;

  // Méthode pour changer le niveau de retard
  void _updateRetard(int level) {
    setState(() {
      _selectedLevel = level;
    });
    retardNotifier.value = _selectedLevel; // Met à jour l'état en temps réel
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Retards'),
        backgroundColor: Colors.blueAccent,
        // Pas de bouton retour en arrière dans l'écran personnel
        leading: Container(), // On supprime simplement l'icône
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Sélectionnez le niveau de retard:', style: TextStyle(fontSize: 18)),
            DropdownButton<int>(
              value: _selectedLevel,
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value!;
                });
                _updateRetard(_selectedLevel); // Met à jour l'état du retard
              },
              items: const [
                DropdownMenuItem(value: 0, child: Text('Pas de retard')),
                DropdownMenuItem(value: 1, child: Text('Léger retard')),
                DropdownMenuItem(value: 2, child: Text('Retard conséquent')),
              ],
            ),
            ElevatedButton(
              onPressed: () => _updateRetard(_selectedLevel),
              child: const Text('Mettre à jour le retard'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 30),
            // Nouveau bouton "Se déconnecter"
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text(
                'Se déconnecter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white, // Changer la couleur du texte ici
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ValueNotifier global qui gère le niveau de retard
final ValueNotifier<int> retardNotifier = ValueNotifier<int>(0);