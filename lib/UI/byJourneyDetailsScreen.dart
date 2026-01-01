import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:the_read_thread/Controller/MemoryController.dart';

class ByJourneyDetailsScreen extends StatelessWidget {
  final String journeyName;
  final List<MemoryItem> memories;

  const ByJourneyDetailsScreen({
    Key? key,
    required this.journeyName,
    required this.memories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group memories by date
    final Map<String, List<MemoryItem>> groupedByDate = {};

    for (var memory in memories) {
      final dateKey = memory.completedAt != null
          ? DateFormat('MMMM d, yyyy').format(memory.completedAt!)
          : 'no_date'.tr;

      groupedByDate.putIfAbsent(dateKey, () => []).add(memory);
    }

    // Sort dates: newest first
    final sortedDates = groupedByDate.keys.toList()
      ..sort((b, a) => a.compareTo(b)); // descending

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(
          journeyName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle: Total memories
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Text(
              "${memories.length} ${memories.length == 1 ? 'memory'.tr : 'memories'.tr}",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // List of memories grouped by date
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final dayMemories = groupedByDate[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Header
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAE1B25),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Red underline
                    Divider(thickness: 2, color: Color(0xFFAE1B25)),
                    const SizedBox(height: 18),

                    // Memories for this date
                    ...dayMemories
                        .map((memory) => MemoryCard(memory: memory))
                        .toList(),

                    // Extra spacing before next date
                    const SizedBox(height: 28),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Single memory row with photo + title
class MemoryCard extends StatelessWidget {
  final MemoryItem memory;

  const MemoryCard({required this.memory, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- TOP IMAGE ----------
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            child: Image.network(
              memory.coverImageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          // ---------- TITLE SECTION ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Text(
              memory.memoryDetails,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}