class MultiUploadResponse {
  String status;
  List<Media> media;

  MultiUploadResponse({
    required this.status,
    required this.media,
  });

  factory MultiUploadResponse.fromJson(dynamic json) {
    final status = json["status"] as String;
    final media = List.from(json["results"]).map((item) {
      return Media.fromJson(item);
    }).toList();

    return MultiUploadResponse(
      status: status,
      media: media,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "status": status,
      "media": media.map((item) => item.toJson()).toList(),
    };
  }
}

class SingleUploadResponse {
  String status;
  Media media;

  SingleUploadResponse({
    required this.status,
    required this.media,
  });

  factory SingleUploadResponse.fromJson(dynamic json) {
    final status = json["status"] as String;
    final media = Media.fromJson(json["media"]);

    return SingleUploadResponse(
      status: status,
      media: media,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "status": status,
      "media": media.toJson(),
    };
  }
}

class Media {
  String url;
  String type;

  Media({
    required this.url,
    required this.type,
  });

  factory Media.fromJson(dynamic json) {
    final type = json["type"] as String;
    final url = json["url"] as String;

    return Media(
      url: url,
      type: type,
    );
  }

  Map<String, String> toJson() {
    return {
      "url": url,
      "type": type,
    };
  }
}
