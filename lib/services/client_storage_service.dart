import 'package:shared_preferences/shared_preferences.dart';
import 'package:fatora/models/client_model.dart';

class ClientStorageService {
  static const String _storageKey = 'saved_clients';

  static Future<void> saveClient(ClientModel client) async {
    final trimmedName = client.name.trim();
    if (trimmedName.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final clients = prefs.getStringList(_storageKey) ?? [];
    clients.removeWhere((item) {
      try {
        return ClientModel.fromJson(item).id == trimmedName.toLowerCase();
      } catch (e) {
        return true;
      }
    });
    clients.insert(
      0,
      ClientModel(
        name: trimmedName,
        email: client.email.trim(),
        phone: client.phone.trim(),
      ).toJson(),
    );
    await prefs.setStringList(_storageKey, clients);
  }

  static Future<List<ClientModel>> getClients() async {
    final prefs = await SharedPreferences.getInstance();
    final clients = prefs.getStringList(_storageKey) ?? [];
    return clients
        .map((item) {
          try {
            return ClientModel.fromJson(item);
          } catch (e) {
            return null;
          }
        })
        .whereType<ClientModel>()
        .where((client) => client.name.trim().isNotEmpty)
        .toList();
  }

  static Future<void> deleteClient(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final clients = prefs.getStringList(_storageKey) ?? [];
    clients.removeWhere((item) {
      try {
        return ClientModel.fromJson(item).id == name.trim().toLowerCase();
      } catch (e) {
        return true;
      }
    });
    await prefs.setStringList(_storageKey, clients);
  }
}
