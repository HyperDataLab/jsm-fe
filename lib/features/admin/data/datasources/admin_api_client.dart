import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';

/// Centralized API Client for Admin Data Pipeline operations.
/// Connects all Admin Console views to the live FastAPI backend.
class AdminApiClient {
  final http.Client _client;
  final Future<String?> Function()? tokenProvider;

  AdminApiClient({this.tokenProvider, http.Client? client})
    : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = tokenProvider != null ? await tokenProvider!() : null;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ── 1. Journals Endpoints ─────────────────────────────────────
  Future<List<Map<String, dynamic>>> getJournals({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiEndpoints.adminJournals}?page=$page&per_page=$perPage',
      );
      final res = await _client.get(uri, headers: await _headers());
      if (res.statusCode == 200) {
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final data = body['data'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }
      }
      throw ServerException('Không thể tải danh sách tạp chí', res.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Lỗi kết nối máy chủ: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchOpenAlexJournals(
    String query,
  ) async {
    try {
      final uri = Uri.parse(
        '${ApiEndpoints.adminOpenAlexJournals}?search=${Uri.encodeComponent(query)}',
      );
      final res = await _client.get(uri, headers: await _headers());
      if (res.statusCode == 200) {
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          final list = data['items'] ?? data['results'];
          if (list is List) {
            return list.whereType<Map<String, dynamic>>().toList();
          }
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> importJournal({
    required String openalexId,
    required String title,
    String? issnL,
    List<String>? issns,
    String? publisher,
    String? homepageUrl,
    int? worksCount,
    int? citedByCount,
    String? field,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.adminImportJournal);
      final res = await _client.post(
        uri,
        headers: await _headers(),
        body: jsonEncode({
          'openalex_id': openalexId,
          'title': title,
          'issn_l': issnL,
          'issns': issns ?? (issnL != null ? [issnL] : []),
          'publisher': publisher,
          'homepage_url': homepageUrl,
          'works_count': ?worksCount,
          'cited_by_count': ?citedByCount,
          'field': ?field,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return (body['data'] as Map<String, dynamic>?) ?? {};
      }
      throw ServerException('Lỗi khi đăng ký tạp chí', res.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Lỗi kết nối máy chủ: $e');
    }
  }

  // ── 2. Configurations Endpoints ───────────────────────────────
  Future<List<Map<String, dynamic>>> getConfigurations() async {
    try {
      final uri = Uri.parse(ApiEndpoints.adminConfigurations);
      final res = await _client.get(uri, headers: await _headers());
      if (res.statusCode == 200) {
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final data = body['data'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }
      }
      throw ServerException('Không thể tải cấu hình khai phá', res.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Lỗi kết nối máy chủ: $e');
    }
  }

  Future<Map<String, dynamic>> createConfiguration({
    required String journalId,
    required String domain,
    required int yearFrom,
    required int yearTo,
    required int targetArticles,
    String? referenceCorpusName,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.adminConfigurations);
      final res = await _client.post(
        uri,
        headers: await _headers(),
        body: jsonEncode({
          'journal_id': journalId,
          'domain': domain,
          'year_from': yearFrom,
          'year_to': yearTo,
          'target_articles': targetArticles,
          'reference_corpus_name': referenceCorpusName,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return (body['data'] as Map<String, dynamic>?) ?? {};
      }
      throw ServerException('Lỗi khi tạo cấu hình', res.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Lỗi kết nối máy chủ: $e');
    }
  }

  Future<Map<String, dynamic>> updateConfiguration(
    String configId, {
    int? yearFrom,
    int? yearTo,
    int? targetArticles,
    String? domain,
    bool? isActive,
  }) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.adminConfigurations}/$configId');
      final res = await _client.put(
        uri,
        headers: await _headers(),
        body: jsonEncode({
          'year_from': ?yearFrom,
          'year_to': ?yearTo,
          'target_articles': ?targetArticles,
          'domain': ?domain,
          'is_active': ?isActive,
        }),
      );
      if (res.statusCode == 200) {
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return (body['data'] as Map<String, dynamic>?) ?? {};
      }
      throw ServerException('Lỗi khi cập nhật cấu hình', res.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Lỗi kết nối máy chủ: $e');
    }
  }

  Future<void> deleteConfiguration(String configId) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.adminConfigurations}/$configId');
      final res = await _client.delete(uri, headers: await _headers());
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw ServerException('Không thể xóa cấu hình', res.statusCode);
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Lỗi kết nối máy chủ: $e');
    }
  }

  Future<Map<String, dynamic>> triggerAnalysis(String configId) async {
    try {
      final uri = Uri.parse(
        '${ApiEndpoints.adminConfigurations}/$configId/analyze',
      );
      final res = await _client.post(uri, headers: await _headers());
      if (res.statusCode == 200 ||
          res.statusCode == 201 ||
          res.statusCode == 202) {
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return (body['data'] as Map<String, dynamic>?) ?? {};
      }
      throw ServerException(
        'Không thể kích hoạt tác vụ phân tích',
        res.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Lỗi kết nối máy chủ: $e');
    }
  }

  // ── 3. Job Monitor Endpoints ──────────────────────────────────
  Future<List<Map<String, dynamic>>> getAnalysisJobs({
    String? journalId,
    String? status,
  }) async {
    try {
      final queryParams = <String>[];
      if (journalId != null) queryParams.add('journal_id=$journalId');
      if (status != null) queryParams.add('status=$status');
      final qs = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

      final uri = Uri.parse('${ApiEndpoints.adminAnalysisJobs}$qs');
      final res = await _client.get(uri, headers: await _headers());
      if (res.statusCode == 200) {
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final data = body['data'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }
      }
      throw ServerException('Không thể tải danh sách tác vụ', res.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Lỗi kết nối máy chủ: $e');
    }
  }

  Future<Map<String, dynamic>> getJobMetrics(String jobId) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.adminAnalysisJobs}/$jobId/metrics');
      final res = await _client.get(uri, headers: await _headers());
      if (res.statusCode == 200) {
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return (body['data'] as Map<String, dynamic>?) ?? {};
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getJobArticles(
    String jobId, {
    int page = 1,
    int perPage = 50,
    String? status,
  }) async {
    try {
      final queryParams = <String>['page=$page', 'per_page=$perPage'];
      if (status != null) queryParams.add('status=$status');
      final uri = Uri.parse(
        '${ApiEndpoints.adminAnalysisJobs}/$jobId/articles?${queryParams.join('&')}',
      );
      final res = await _client.get(uri, headers: await _headers());
      if (res.statusCode == 200) {
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final data = body['data'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<int> retryFailedArticles(String jobId) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.adminAnalysisJobs}/$jobId/retry');
      final res = await _client.post(uri, headers: await _headers());
      if (res.statusCode == 200) {
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        return (data?['retried_count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> cancelJob(String jobId) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.adminAnalysisJobs}/$jobId/cancel');
      final res = await _client.post(uri, headers: await _headers());
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteJob(String jobId) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.adminAnalysisJobs}/$jobId');
      final res = await _client.delete(uri, headers: await _headers());
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── 4. Corpus Snapshots ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSnapshots() async {
    try {
      final uri = Uri.parse(ApiEndpoints.adminSnapshots);
      final res = await _client.get(uri, headers: await _headers());
      if (res.statusCode == 200) {
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final data = body['data'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── 5. Style Profiles Review ──────────────────────────────────
  Future<List<Map<String, dynamic>>> getStyleProfiles({
    String? journalId,
  }) async {
    try {
      final qs = journalId != null ? '?journal_id=$journalId' : '';
      final uri = Uri.parse('${ApiEndpoints.adminStyleProfiles}$qs');
      final res = await _client.get(uri, headers: await _headers());
      if (res.statusCode == 200) {
        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final data = body['data'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── 6. Overview & Monitor Statistics ──────────────────────────
  Future<Map<String, dynamic>> getOverviewStats() async {
    try {
      final uri = Uri.parse(ApiEndpoints.monitorStats);
      final res = await _client.get(uri, headers: await _headers());
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse(ApiEndpoints.systemHealth);
      final res = await _client.get(uri).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
