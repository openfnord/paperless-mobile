import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/linked_documents_preview/bloc/state/linked_documents_state.dart';

@injectable
class LinkedDocumentsCubit extends Cubit<LinkedDocumentsState> {
  final PaperlessDocumentsApi _api;

  LinkedDocumentsCubit(this._api) : super(LinkedDocumentsState());

  Future<void> initialize(DocumentFilter filter) async {
    final documents = await _api.find(
      filter.copyWith(
        pageSize: 100,
      ),
    );
    emit(LinkedDocumentsState(
      isLoaded: true,
      documents: documents,
      filter: filter,
    ));
  }
}