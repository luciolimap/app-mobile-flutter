import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/services/location_service.dart';
import 'package:mobile/features/inspection/bloc/inspection_form_bloc.dart';
import 'package:mobile/features/inspection/data/form_schema.dart';
import 'package:mobile/features/inspection/data/form_schema_repository.dart';
import 'package:mobile/features/inspection/data/inspection_repository.dart';
import 'package:mobile/features/sync/sync_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockInspectionRepository extends Mock implements InspectionRepository {}

class _MockSyncService extends Mock implements SyncService {}

class _MockLocationService extends Mock implements LocationService {}

class _MockFormSchemaRepository extends Mock implements FormSchemaRepository {}

void main() {
  late _MockInspectionRepository repository;
  late _MockSyncService syncService;
  late _MockLocationService locationService;

  const workOrderId = 'wo_1001';
  // ~7.12 km south of the work order, well past the 200 m geofence.
  const workOrderLat = -7.1195;
  const workOrderLng = -34.8450;

  setUp(() {
    repository = _MockInspectionRepository();
    syncService = _MockSyncService();
    locationService = _MockLocationService();
    when(() => syncService.syncAll()).thenAnswer((_) async {});
    when(() => repository.saveInspection(
          workOrderId: any(named: 'workOrderId'),
          observation: any(named: 'observation'),
          condition: any(named: 'condition'),
          photoPath: any(named: 'photoPath'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          capturedAt: any(named: 'capturedAt'),
          asDraft: any(named: 'asDraft'),
        )).thenAnswer((_) async {});
  });

  InspectionFormBloc buildBloc() => InspectionFormBloc(
        workOrderId: workOrderId,
        workOrderLatitude: workOrderLat,
        workOrderLongitude: workOrderLng,
        repository: repository,
        syncService: syncService,
        locationService: locationService,
      );

  group('InspectionCompletePressed validation', () {
    blocTest<InspectionFormBloc, InspectionFormState>(
      'rejects an observation shorter than 10 characters',
      build: buildBloc,
      seed: () => const InspectionFormState(observation: 'curta'),
      act: (bloc) => bloc.add(const InspectionCompletePressed()),
      expect: () => [
        isA<InspectionFormState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'A observação precisa ter ao menos 10 caracteres.',
        ),
      ],
      verify: (_) {
        verifyNever(() => repository.saveInspection(
              workOrderId: any(named: 'workOrderId'),
              observation: any(named: 'observation'),
              condition: any(named: 'condition'),
              photoPath: any(named: 'photoPath'),
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
              capturedAt: any(named: 'capturedAt'),
              asDraft: any(named: 'asDraft'),
            ));
      },
    );

    blocTest<InspectionFormBloc, InspectionFormState>(
      'rejects a missing photo even with a valid observation',
      build: buildBloc,
      seed: () => const InspectionFormState(
        observation: 'Observação com mais de dez caracteres',
      ),
      act: (bloc) => bloc.add(const InspectionCompletePressed()),
      expect: () => [
        isA<InspectionFormState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'Anexe uma foto da evidência.',
        ),
      ],
    );

    blocTest<InspectionFormBloc, InspectionFormState>(
      'rejects a missing location even with observation and photo',
      build: buildBloc,
      seed: () => const InspectionFormState(
        observation: 'Observação com mais de dez caracteres',
        photoPath: '/tmp/foto.jpg',
      ),
      act: (bloc) => bloc.add(const InspectionCompletePressed()),
      expect: () => [
        isA<InspectionFormState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'Capture a localização da inspeção.',
        ),
      ],
    );

    blocTest<InspectionFormBloc, InspectionFormState>(
      'saves as pending and triggers a sync attempt when everything is valid',
      build: buildBloc,
      seed: () => const InspectionFormState(
        observation: 'Observação com mais de dez caracteres',
        photoPath: '/tmp/foto.jpg',
        latitude: -7.12,
        longitude: -34.846,
      ),
      act: (bloc) => bloc.add(const InspectionCompletePressed()),
      expect: () => [
        isA<InspectionFormState>().having((s) => s.isSaving, 'isSaving', true),
        isA<InspectionFormState>().having(
          (s) => s.saveResult,
          'saveResult',
          InspectionSaveResult.completed,
        ),
      ],
      verify: (_) {
        verify(() => repository.saveInspection(
              workOrderId: workOrderId,
              observation: 'Observação com mais de dez caracteres',
              condition: null,
              photoPath: '/tmp/foto.jpg',
              latitude: -7.12,
              longitude: -34.846,
              capturedAt: any(named: 'capturedAt'),
              asDraft: false,
            )).called(1);
        verify(() => syncService.syncAll()).called(1);
      },
    );
  });

  group('InspectionSaveDraftPressed', () {
    blocTest<InspectionFormBloc, InspectionFormState>(
      'requires at least some observation text',
      build: buildBloc,
      act: (bloc) => bloc.add(const InspectionSaveDraftPressed()),
      expect: () => [
        isA<InspectionFormState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'Escreva ao menos uma observação.',
        ),
      ],
    );

    blocTest<InspectionFormBloc, InspectionFormState>(
      'saves a draft without requiring photo or location',
      build: buildBloc,
      seed: () => const InspectionFormState(observation: 'Rascunho inicial'),
      act: (bloc) => bloc.add(const InspectionSaveDraftPressed()),
      expect: () => [
        isA<InspectionFormState>().having((s) => s.isSaving, 'isSaving', true),
        isA<InspectionFormState>().having(
          (s) => s.saveResult,
          'saveResult',
          InspectionSaveResult.draftSaved,
        ),
      ],
      verify: (_) {
        verify(() => repository.saveInspection(
              workOrderId: workOrderId,
              observation: 'Rascunho inicial',
              condition: null,
              photoPath: '',
              latitude: 0,
              longitude: 0,
              capturedAt: any(named: 'capturedAt'),
              asDraft: true,
            )).called(1);
        verifyNever(() => syncService.syncAll());
      },
    );
  });

  group('InspectionLocationRequested (geofence)', () {
    blocTest<InspectionFormBloc, InspectionFormState>(
      'flags the inspection as far from the work order past 200 m',
      build: buildBloc,
      setUp: () => when(() => locationService.getCurrentLocation()).thenAnswer(
        (_) async => Position(
          latitude: -7.19, // ~8 km away from the work order coordinates
          longitude: -34.90,
          timestamp: DateTime(2026, 8, 17),
          accuracy: 5,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      ),
      act: (bloc) => bloc.add(const InspectionLocationRequested()),
      expect: () => [
        isA<InspectionFormState>()
            .having((s) => s.isCapturingLocation, 'isCapturingLocation', true),
        isA<InspectionFormState>()
            .having((s) => s.isFarFromWorkOrder, 'isFarFromWorkOrder', true),
      ],
    );
  });

  group('InspectionSchemaRequested', () {
    blocTest<InspectionFormBloc, InspectionFormState>(
      'is a no-op and keeps the default fields when there is no schema repository',
      build: buildBloc,
      act: (bloc) => bloc.add(const InspectionSchemaRequested()),
      expect: () => [],
      verify: (bloc) {
        expect(bloc.state.schema, isNull);
        expect(bloc.state.minObservationLength, 10);
        expect(bloc.state.conditionOptions, ['bom', 'regular', 'ruim', 'crítico']);
      },
    );

    blocTest<InspectionFormBloc, InspectionFormState>(
      'applies the fetched schema (labels, min length, condition options)',
      build: () {
        final schemaRepository = _MockFormSchemaRepository();
        when(() => schemaRepository.fetch(workOrderId)).thenAnswer(
          (_) async => const InspectionFormSchema(
            workOrderId: workOrderId,
            fields: [
              InspectionFormFieldSpec(
                key: 'observation',
                type: 'text',
                label: 'Observação da inspeção',
                required: true,
                minLength: 20,
              ),
              InspectionFormFieldSpec(
                key: 'condition',
                type: 'select',
                label: 'Estado do ativo',
                required: true,
                options: ['ótimo', 'ruim'],
              ),
            ],
          ),
        );
        return InspectionFormBloc(
          workOrderId: workOrderId,
          workOrderLatitude: workOrderLat,
          workOrderLongitude: workOrderLng,
          repository: repository,
          syncService: syncService,
          locationService: locationService,
          schemaRepository: schemaRepository,
        );
      },
      act: (bloc) => bloc.add(const InspectionSchemaRequested()),
      expect: () => [
        isA<InspectionFormState>()
            .having((s) => s.minObservationLength, 'minObservationLength', 20)
            .having((s) => s.conditionOptions, 'conditionOptions', ['ótimo', 'ruim']),
      ],
    );

    blocTest<InspectionFormBloc, InspectionFormState>(
      'keeps the default fields when the schema fetch fails (e.g. offline)',
      build: () {
        final schemaRepository = _MockFormSchemaRepository();
        when(() => schemaRepository.fetch(workOrderId)).thenAnswer((_) async => null);
        return InspectionFormBloc(
          workOrderId: workOrderId,
          workOrderLatitude: workOrderLat,
          workOrderLongitude: workOrderLng,
          repository: repository,
          syncService: syncService,
          locationService: locationService,
          schemaRepository: schemaRepository,
        );
      },
      act: (bloc) => bloc.add(const InspectionSchemaRequested()),
      expect: () => [],
      verify: (bloc) => expect(bloc.state.schema, isNull),
    );
  });
}
