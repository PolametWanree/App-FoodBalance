import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class ChatGemini extends StatefulWidget {
  const ChatGemini({super.key});

  @override
  State<ChatGemini> createState() => _ChatGeminiState();
}

class _ChatGeminiState extends State<ChatGemini> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "FoodBalance",
    profileImage:
        "assets/images/icon.png",
  );

  List<XFile> selectedImages = [];
  TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Heathy Chat"),
      ),
      body: Column(
        children: [
          Expanded(
  child: DashChat(
    currentUser: currentUser, // ผู้ใช้ปัจจุบัน
    messages: messages, // รายการข้อความ
    inputOptions: InputOptions(
      trailing: [
        IconButton(
          onPressed: _pickImage,
          icon: const Icon(Icons.image),
        ),
        if (selectedImages.isNotEmpty || messageController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (selectedImages.isNotEmpty) {
                _sendMediaMessage();
              } else if (messageController.text.isNotEmpty) {
                _sendMessage(ChatMessage(
                  user: currentUser,
                  createdAt: DateTime.now(),
                  text: messageController.text,
                ));
              }
            },
          ),
      ],
      textController: messageController,
      inputDecoration: InputDecoration(
        hintText: 'Type a message...',
        fillColor: Colors.grey[200], // เปลี่ยนสีพื้นหลังของกล่องข้อความ
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: const BorderSide(
            color: Colors.blue, // สีขอบกล่องข้อความ
            width: 2.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: const BorderSide(
            color: Colors.grey, // สีขอบเมื่อไม่ได้โฟกัส
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 13, 93, 49), // สีขอบเมื่อโฟกัส
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        prefixIcon: const Icon(Icons.message, color: Color.fromRGBO(33, 150, 243, 1)),
      ),
    ),
    messageOptions: MessageOptions(
      // สีและรูปร่างของฟองข้อความสำหรับผู้ใช้ปัจจุบัน
      currentUserContainerColor: Colors.blueAccent, // สีฟองข้อความของผู้ใช้ปัจจุบัน
      currentUserTextColor: Colors.white, // สีข้อความของผู้ใช้ปัจจุบัน
      // สีและรูปร่างของฟองข้อความสำหรับผู้ใช้คนอื่น
      containerColor: const Color.fromARGB(255, 82, 179, 96), // สีฟองข้อความของคู่สนทนา
      textColor: const Color.fromARGB(255, 255, 255, 255), // สีข้อความของคู่สนทนา
    ),
    onSend: (ChatMessage message) {
      if (selectedImages.isNotEmpty) {
        _sendMediaMessage();
      } else {
        _sendMessage(message);
      }
    },
  ),
),



          if (selectedImages.isNotEmpty) _buildImagePreview(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 80, // ขนาดความสูงของภาพตัวอย่าง
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == selectedImages.length) {
                    return GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 78, 177, 118),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Icon(Icons.add, size: 40, color: Colors.white),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.file(
                          File(selectedImages[index].path),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedImages.removeAt(index);
                            });
                          },
                          child: const Icon(Icons.close, color: Colors.red, size: 20),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
  setState(() {
    messages = [chatMessage, ...messages];
    messageController.clear();
  });

  try {
    String question = chatMessage.text;
    List<Uint8List>? images;
    if (chatMessage.medias?.isNotEmpty ?? false) {
      images = [
        File(chatMessage.medias!.first.url).readAsBytesSync(),
      ];
    }

    // เก็บข้อความที่รับเข้ามาจาก stream
    StringBuffer responseBuffer = StringBuffer();

    // ใช้ stream เพื่อดึงข้อมูลทีละน้อย
    gemini.streamGenerateContent(
      question,
      images: images,
    ).listen((event) {
      // ต่อข้อความที่ได้จาก stream เข้ากับ buffer
      String responsePart = event.content?.parts?.fold(
            "",
            (previous, current) => "$previous ${current.text}",
          ) ?? "";

      responseBuffer.write(responsePart);
    }, onDone: () {
      // เมื่อ stream ทำงานเสร็จสิ้น จะแสดงผลข้อความทั้งหมด
      String finalResponse = responseBuffer.toString();

      // สร้างข้อความจาก Gemini แล้วเพิ่มใน UI
      ChatMessage geminiMessage = ChatMessage(
        user: geminiUser,
        createdAt: DateTime.now(),
        text: finalResponse, // ข้อความทั้งหมดที่เก็บใน buffer
      );

      setState(() {
        messages = [geminiMessage, ...messages];
      });
    });
  } catch (e) {
    print(e);
  }
}



  void _pickImage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (file != null) {
      setState(() {
        selectedImages.add(file);
      });
    }
  }

  void _sendMediaMessage() {
  if (selectedImages.isNotEmpty) {
    // สร้าง prompt ที่จะใช้เมื่อส่งรูปภาพ (ไม่แสดง prompt ใน UI)
    String prompt = "อาหารอันนี้คืออะไร ได้โภชนาการอะไรบ้าง เช่นแป้ง น้ำตาล โปรตีน ไขมัน แร่ธาตุ วิตามิน บอกมาเป็นตัวเลขคร่าวๆโดยประมาณ และจัดเรียงข้อความให้สวยงามก่อนส่ง เช่น เริ่มด้วย คาร์โบไอเดรต โปรตีน น้ำตาล และท้ายสุดด้วยคำอธิบาย";

    // สร้างรายการ ChatMedia สำหรับรูปภาพที่ผู้ใช้เลือก
    List<ChatMedia> medias = selectedImages.map((image) {
      return ChatMedia(
        url: image.path,
        fileName: "",
        type: MediaType.image,
      );
    }).toList();

    // สร้างข้อความที่จะส่งไปยัง UI (แสดงเฉพาะข้อความของผู้ใช้)
    ChatMessage chatMessage = ChatMessage(
      user: currentUser,
      createdAt: DateTime.now(),
      text: messageController.text, // แสดงเฉพาะข้อความของผู้ใช้
      medias: medias,
    );

    // ส่งข้อความของผู้ใช้ไปยัง UI
    setState(() {
      messages = [chatMessage, ...messages];
      messageController.clear();
    });

    // ส่ง prompt และรูปภาพไปยัง Gemini (ไม่แสดง prompt ใน UI)
    gemini
        .streamGenerateContent(
          prompt, // ส่ง prompt แทนข้อความของผู้ใช้
          images: selectedImages.map((image) => File(image.path).readAsBytesSync()).toList(),
        )
        .listen((event) {
      String response = event.content?.parts?.fold(
            "",
            (previous, current) => "$previous ${current.text}",
          ) ??
          "";

      ChatMessage geminiMessage = ChatMessage(
        user: geminiUser,
        createdAt: DateTime.now(),
        text: response, // แสดงผลลัพธ์จาก Gemini
      );

      setState(() {
        messages = [geminiMessage, ...messages];
      });
    });

    // เคลียร์รูปภาพที่เลือก
    setState(() {
      selectedImages.clear();
    });
  }
}


}