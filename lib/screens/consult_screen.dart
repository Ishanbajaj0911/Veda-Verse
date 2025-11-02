import 'package:flutter/material.dart';

class ConsultScreen extends StatefulWidget {
  const ConsultScreen({super.key});

  @override
  State<ConsultScreen> createState() => _ConsultScreenState();
}

class _ConsultScreenState extends State<ConsultScreen> {
  String? _selectedService;
  String? _selectedType;
  String? _selectedDate;
  String? _selectedTime;
  bool _agreePolicy = false;

  final List<Map<String, dynamic>> _experts = [
    {
      "name": "Dr. Priya Sharma",
      "role": "Ayurvedic Physician",
      "rating": 4.9,
      "reviews": 210,
      "image": "assets/doctors/priya.png",
    },
    {
      "name": "Yogi Raj",
      "role": "Yoga & Meditation Expert",
      "rating": 4.7,
      "reviews": 155,
      "image": "assets/doctors/raj.png",
    },
    {
      "name": "Dr. Alok Singh",
      "role": "Holistic Nutritionist",
      "rating": 4.8,
      "reviews": 180,
      "image": "assets/doctors/alok.png",
    },
  ];

  final List<String> _services = [
    "Ayurveda Consultation",
    "Yoga & Pranayama Session",
    "Diet & Lifestyle Coaching",
    "Mental Wellness Support",
  ];

  final List<String> _consultationTypes = [
    "Video Call (30 min)",
    "Video Call (60 min)",
    "In-Person (Clinic visit)",
    "Chat Consultation",
  ];

  final List<String> _availableDates = [
    "Mon, Oct 21",
    "Tue, Oct 22",
    "Wed, Oct 23",
    "Thu, Oct 24",
    "Fri, Oct 25"
  ];

  final Map<String, List<String>> _timeSlots = {
    "Wed, Oct 23": ["09:00 AM", "10:30 AM", "02:00 PM", "04:30 PM"],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:const Color.fromARGB(179, 209, 214, 214),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "Book a Consultation",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color.fromARGB(245, 45, 103, 132),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 🌿 Meet Our Experts
              _sectionTitle("Meet Our Experts", "Find the right holistic practitioner for you."),
              const SizedBox(height: 14),

              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _experts.length,
                  itemBuilder: (context, index) {
                    final doc = _experts[index];
                    return Container(
                      width: 180,
                      
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(1, 3),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 34,
                                backgroundImage: AssetImage(doc["image"]),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                doc["name"],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                doc["role"],
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${doc["rating"]} (${doc["reviews"]})",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color.fromARGB(245, 54, 111, 139),
                                  side: const BorderSide(color: const Color.fromARGB(245, 54, 111, 139)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () {},
                                child: const Text(
                                  "View Profile",
                                  style: TextStyle(fontSize: 12),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "View All Experts",
                    style: TextStyle(color: const Color.fromARGB(245, 54, 111, 139)),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 🌸 Select Service
              _sectionTitle("Select Your Service",
                  "What kind of consultation do you need?"),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _services.map((service) {
                  final selected = _selectedService == service;
                  return ChoiceChip(
                    label: Text(service),
                    selected: selected,
                    onSelected: (val) =>
                        setState(() => _selectedService = service),
                    selectedColor: const Color.fromARGB(245, 54, 111, 139),
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: "Consultation Type",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _consultationTypes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v),
              ),

              const SizedBox(height: 25),

              // 🗓 Choose Slot
              _sectionTitle("Choose Your Slot", "When would you like to meet?"),
              const SizedBox(height: 10),

              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableDates.length,
                  itemBuilder: (context, index) {
                    final date = _availableDates[index];
                    final selected = _selectedDate == date;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color.fromARGB(245, 54, 111, 139)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            date,
                            style: TextStyle(
                              color:
                                  selected ? Colors.white : Colors.grey.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              if (_selectedDate != null)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _timeSlots["Wed, Oct 23"]!.map((time) {
                    final selected = _selectedTime == time;
                    return ChoiceChip(
                      label: Text(time),
                      selected: selected,
                      selectedColor: const Color.fromARGB(245, 54, 111, 139),
                      onSelected: (val) => setState(() => _selectedTime = time),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 8),
              const Text(
                "All times are in your local timezone.",
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),

              const SizedBox(height: 25),

              // 🧘 Summary
              _sectionTitle("Summary & Payment", "Your appointment details."),
              const SizedBox(height: 10),
              _summaryTile("Doctor", "Dr. Priya Sharma"),
              _summaryTile("Service", "Ayurveda Consultation (Video Call, 30 min)"),
              _summaryTile("Date & Time", "Wed, Oct 25, 2:00 PM"),
              _summaryTile("Price", "₹49.00"),

              Row(
                children: [
                  Checkbox(
                    value: _agreePolicy,
                    activeColor: const Color.fromARGB(245, 54, 111, 139),
                    onChanged: (val) => setState(() => _agreePolicy = val!),
                  ),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        text: "I agree to the ",
                        style: TextStyle(color: Colors.black87),
                        children: [
                          TextSpan(
                            text: "cancellation policy.",
                            style: TextStyle(
                              color: const Color.fromARGB(245, 54, 111, 139),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(245, 54, 111, 139),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 6,
                  ),
                  onPressed: _agreePolicy ? () {} : null,
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: const Text(
                    "Confirm Booking",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:const Color.fromARGB(245, 54, 111, 139))),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _summaryTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
