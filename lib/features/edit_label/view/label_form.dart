import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/translation/matching_algorithm_localization_mapper.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/home/view/model/api_version.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

import 'package:paperless_mobile/helpers/message_helpers.dart';

class SubmitButtonConfig<T extends Label> {
  final Widget icon;
  final Widget label;
  final Future<T> Function(T) onSubmit;

  SubmitButtonConfig({
    required this.icon,
    required this.label,
    required this.onSubmit,
  });
}

class LabelForm<T extends Label> extends StatefulWidget {
  final T? initialValue;

  final SubmitButtonConfig<T> submitButtonConfig;

  /// FromJson method to parse the form field values into a label instance.
  final T Function(Map<String, dynamic> json) fromJsonT;

  /// List of additionally rendered form fields.
  final List<Widget> additionalFields;

  final bool autofocusNameField;

  const LabelForm({
    Key? key,
    required this.initialValue,
    required this.fromJsonT,
    this.additionalFields = const [],
    required this.submitButtonConfig,
    required this.autofocusNameField,
  }) : super(key: key);

  @override
  State<LabelForm> createState() => _LabelFormState<T>();
}

class _LabelFormState<T extends Label> extends State<LabelForm<T>> {
  final _formKey = GlobalKey<FormBuilderState>();

  late bool _enableMatchFormField;

  PaperlessValidationErrors _errors = {};

  @override
  void initState() {
    super.initState();
    var matchingAlgorithm = (widget.initialValue?.matchingAlgorithm ??
        MatchingAlgorithm.defaultValue);
    _enableMatchFormField = matchingAlgorithm != MatchingAlgorithm.auto &&
        matchingAlgorithm != MatchingAlgorithm.none;
  }

  @override
  Widget build(BuildContext context) {
    List<MatchingAlgorithm> selectableMatchingAlgorithmValues =
        getSelectableMatchingAlgorithmValues(
            context.watch<ApiVersion>().hasMultiUserSupport);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton.extended(
        icon: widget.submitButtonConfig.icon,
        label: widget.submitButtonConfig.label,
        onPressed: _onSubmit,
      ),
      body: FormBuilder(
        key: _formKey,
        child: ListView(
          children: [
            FormBuilderTextField(
              autofocus: widget.autofocusNameField,
              name: Label.nameKey,
              decoration: InputDecoration(
                labelText: S.of(context)!.name,
                errorText: _errors[Label.nameKey],
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return S.of(context)!.thisFieldIsRequired;
                }
                return null;
              },
              initialValue: widget.initialValue?.name,
              onChanged: (val) => setState(() => _errors = {}),
            ),
            FormBuilderDropdown<int?>(
              name: Label.matchingAlgorithmKey,
              initialValue: (widget.initialValue?.matchingAlgorithm ??
                      MatchingAlgorithm.defaultValue)
                  .value,
              decoration: InputDecoration(
                labelText: S.of(context)!.matchingAlgorithm,
                errorText: _errors[Label.matchingAlgorithmKey],
              ),
              onChanged: (val) {
                setState(() {
                  _errors = {};
                  _enableMatchFormField = val != MatchingAlgorithm.auto.value &&
                      val != MatchingAlgorithm.none.value;
                });
              },
              items: selectableMatchingAlgorithmValues
                  .map(
                    (algo) => DropdownMenuItem<int?>(
                      child: Text(
                        translateMatchingAlgorithmDescription(context, algo),
                      ),
                      value: algo.value,
                    ),
                  )
                  .toList(),
            ),
            if (_enableMatchFormField)
              FormBuilderTextField(
                name: Label.matchKey,
                decoration: InputDecoration(
                  labelText: S.of(context)!.match,
                  errorText: _errors[Label.matchKey],
                ),
                initialValue: widget.initialValue?.match,
                onChanged: (val) => setState(() => _errors = {}),
              ),
            FormBuilderCheckbox(
              name: Label.isInsensitiveKey,
              initialValue: widget.initialValue?.isInsensitive ?? true,
              title: Text(S.of(context)!.caseIrrelevant),
            ),
            ...widget.additionalFields,
          ].padded(),
        ),
      ),
    );
  }

  List<MatchingAlgorithm> getSelectableMatchingAlgorithmValues(
      bool hasMultiUserSupport) {
    var selectableMatchingAlgorithmValues = MatchingAlgorithm.values;
    if (!hasMultiUserSupport) {
      selectableMatchingAlgorithmValues = selectableMatchingAlgorithmValues
          .where((matchingAlgorithm) =>
              matchingAlgorithm != MatchingAlgorithm.none)
          .toList();
    }
    return selectableMatchingAlgorithmValues;
  }

  void _onSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      try {
        final mergedJson = {
          ...widget.initialValue?.toJson() ?? {},
          ..._formKey.currentState!.value
        };
        final parsed = widget.fromJsonT(mergedJson);
        final createdLabel = await widget.submitButtonConfig.onSubmit(parsed);
        Navigator.pop(context, createdLabel);
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      } on PaperlessValidationErrors catch (errors) {
        setState(() => _errors = errors);
      }
    }
  }
}
