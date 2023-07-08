import 'package:tradeshow_guidance_app/models/project.dart';

class mockApi {
  static Future<List<Project>?> getProjects() async {
   return Project.projectsFromJson("""[{"id": 23,
  "beacon_id": "iaofeafeef324",
  "user_id": 24,
  "user_email": "120770145@gmail.com",
  "user_name": "Paul Caffrey",
  "title": "A Location-Aware Guidance App for Tradeshows",
  "description": "This project will design, implement and test a location-aware smartphone app for guiding users around stands on an event such as a tradeshow.",
  "tags": ["cloud", "bluetooth", "mobile"]},
  {"id": 22,
  "beacon_id": "mgonaie13jeo",
  "user_id": 22,
  "user_email": "paul@gmail.com",
  "user_name": "John Smith",
  "title": "Cell Research Machine Learning",
  "description": "This project focuses on identify different types of diseases from cell analysis using machine learning",
  "tags": ["ai", "machine-learning", "biology"]},
  {"id": 21,
  "beacon_id": "cbaietg12",
  "user_id": 21,
  "user_email": "120770145@gmail.com",
  "user_name": "Mary Brown",
  "title": "Crytographic Analysis of Passwords",
  "description": "This is a project description that is really really really really really really really really really really really long",
  "tags": ["algorithms", "research", "cryptography"]}
  ]""");
  }
}
