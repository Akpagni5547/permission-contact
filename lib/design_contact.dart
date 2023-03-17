import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PageContact extends StatefulWidget {
  const PageContact({Key? key}) : super(key: key);

  @override
  State<PageContact> createState() => _PageContactState();
}

class _PageContactState extends State<PageContact> with WidgetsBindingObserver {
  bool isGranted = false;
  late List<Contact> contactsList = [];
  List<Contact> contactsListFiltered = [];
  bool isLoadingContact = false;
  String errorGetContact = "";
  bool _detectPermission = false;
  TextEditingController searchController = TextEditingController();

  Future<List<Contact>> getPhoneContacts() async {
    Iterable<Contact> contacts = await ContactsService.getContacts();
    return contacts.toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    call(executeAllFunction: true);
  }

  @override
  dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _detectPermission &&
        isGranted == false) {
      _detectPermission = false;
      call(executeAllFunction: false);
    } else if (state == AppLifecycleState.paused && isGranted == false) {
      _detectPermission = true;
    } else if (state == AppLifecycleState.detached) {
    } else if (state == AppLifecycleState.inactive) {}
  }

  void call({required bool executeAllFunction}) async {
    var status = await Permission.contacts.status;
    if (status.isGranted) {
      setState(() {
        isLoadingContact = true;
        isGranted = true;
        errorGetContact = '';
      });
      await Future.delayed(const Duration(seconds: 3));
      try {
        List<Contact> contact = await getPhoneContacts();
        setState(() {
          contactsList = contact;
          isLoadingContact = false;
        });
      } catch (e) {
        setState(() {
          errorGetContact = e.toString();
          isLoadingContact = false;
        });
      }
    } else {
      if (executeAllFunction) {
        requestContact(true);
      }
    }
  }

  static bool validatePhoneNumber(String phone) {
    return RegExp(r"^\+[0-9]{13,}$").hasMatch(phone);
  }

  void requestContact(bool isInitialLaunch) async {
    final askGetContact = await Permission.contacts.request();
    if (askGetContact.isGranted) {
      setState(() {
        isGranted = true;
        isLoadingContact = true;
        errorGetContact = '';
      });
      try {
        List<Contact> contact = await getPhoneContacts();
        setState(() {
          contactsList = contact;
          isLoadingContact = false;
        });
      } catch (e) {
        setState(() {
          errorGetContact = e.toString();
          isLoadingContact = false;
        });
      }
    } else if (askGetContact.isPermanentlyDenied) {
      if (!isInitialLaunch) {
        await showMyDialog();
      }
    } else {
      setState(() {
        errorGetContact = 'Veuillez donner votre autorisation';
      });
    }
  }

  Future<void> showMyDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Demande d'autorisation"),
          content: const Text("Vous avez refuseé de maniere permanente l'acces "
              "a vos contacts. Vous devez activer cela dans vos parametres. "
              "Cliquez sur le bouton oui pour effectuez cette action"),
          actions: [
            TextButton(
              child: const Text("Annuler"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () async {
                // Traitez l'action ici
                Navigator.of(context).pop();
                await openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void searchInContact(String searchInContact) {
    List<Contact> contacts = [];
    contacts.addAll(contactsList);
    if (searchInContact.isNotEmpty) {
      contacts.retainWhere((contact) {
        final String displayNameContact = contact.displayName ?? '';
        final String phoneContact =
            contact.phones == null || contact.phones!.isEmpty
                ? ''
                : contact.phones![0].value!;
        final bool testMatchName = displayNameContact
            .toLowerCase()
            .contains(searchInContact.trim().toLowerCase());

        final bool testMatchNum = phoneContact
            .toLowerCase()
            .contains(searchInContact.trim().toLowerCase());
        return testMatchName || testMatchNum;
      });
    }
    setState(() {
      contactsListFiltered = contacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beneficiaire"),
      ),
      body: SafeArea(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ComponentRecent(),
          Padding(
            padding: const EdgeInsets.only(right: 10, left: 10),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: TextField(
                      controller: searchController,
                      onChanged: (String value) {
                        if (isGranted) {
                          searchInContact(value);
                        }
                      },
                      decoration:
                          const InputDecoration(hintText: "Nom, numero"),
                    )),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                    child: ElevatedButton(
                  onPressed: validatePhoneNumber(
                          searchController.text.trim().toLowerCase())
                      ? () {}
                      : null,
                  child: const Text('valider'),
                ))
              ],
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          const Text('Contacts'),
          Expanded(
            child: ListContact(
              loading: isLoadingContact,
              isSearch: searchController.text.trim() != "",
              granted: isGranted,
              listContact: searchController.text.trim() != ""
                  ? contactsListFiltered
                  : contactsList,
              error: errorGetContact,
              requestContact: () {
                requestContact(false);
              },
            ),
          ),
        ],
      )),
    );
  }
}

class ComponentRecent extends StatelessWidget {
  const ComponentRecent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [Text('Recents')],
        ),
        const SizedBox(
          height: 10,
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
              itemCount: 10,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 10, left: index == 0 ? 5 : 0),
                  child: Column(
                    children: const [
                      CircleAvatar(
                        backgroundColor: Colors.teal,
                      ),
                      Text(
                        'Nom du BN',
                        style: TextStyle(fontSize: 12),
                      )
                    ],
                  ),
                );
              }),
        )
      ],
    );
  }
}

class ListContact extends StatelessWidget {
  final bool loading;
  final bool granted;
  final bool isSearch;
  final String error;
  final void Function() requestContact;
  final List<Contact> listContact;

  const ListContact({
    Key? key,
    required this.loading,
    required this.isSearch,
    required this.granted,
    required this.error,
    required this.requestContact,
    required this.listContact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String message = !granted
        ? "Vous n'avez pas autorisé les contacts, veuillez cliquez sur le bouton autoriser"
        : "Une erreur s'est produite lors de la prise de contact, veuillez cliquez sur ce bouton pour reesayer";
    return loading
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(
                    width: 15,
                  ),
                  Text(
                    'Chargemnt des contacts',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              )
            ],
          )
        : !granted
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          message,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 15),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        requestContact();
                      },
                      child: const Text('Autoriser'))
                ],
              )
            : listContact.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              isSearch
                                  ? 'Aucun trouvé correspondant a votre recherche'
                                  : 'Votre liste de contact est vide',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: listContact.length,
                    itemBuilder: (contextBuilder, index) {
                      final contact = listContact[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child:
                              contact.avatar == null || contact.avatar!.isEmpty
                                  ? const Icon(Icons.person)
                                  : Image.memory(contact.avatar!),
                        ),
                        title: Text(contact.displayName ?? ''),
                        subtitle: Text(
                            contact.phones == null || contact.phones!.isEmpty
                                ? ''
                                : contact.phones![0].value!),
                        trailing: const Icon(Icons.arrow_forward_ios),
                      );
                    },
                  );
  }
}
