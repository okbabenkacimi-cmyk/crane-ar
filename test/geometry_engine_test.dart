import 'package:crane_ar/domain/geometry/geometry_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Work radius  R = L × cos(θ)', () {
    const double l = 10.0;

    test('L=10, θ=0° → R = 10.00 m', () {
      expect(GeometryEngine.workRadius(l, 0), closeTo(10.0, 1e-9));
    });

    test('L=10, θ=30° → R ≈ 8.66 m', () {
      expect(GeometryEngine.workRadius(l, 30), closeTo(8.66, 0.01));
    });

    test('L=10, θ=45° → R ≈ 7.07 m', () {
      expect(GeometryEngine.workRadius(l, 45), closeTo(7.07, 0.01));
    });

    test('L=10, θ=60° → R = 5.00 m', () {
      expect(GeometryEngine.workRadius(l, 60), closeTo(5.0, 1e-9));
    });

    test('L=10, θ=90° → R = 0.00 m', () {
      expect(GeometryEngine.workRadius(l, 90), closeTo(0.0, 1e-9));
    });
  });

  group('Invalid boom length', () {
    test('zero length is rejected', () {
      expect(() => GeometryEngine.workRadius(0, 45),
          throwsA(isA<GeometryValidationException>()));
    });

    test('negative length is rejected', () {
      expect(() => GeometryEngine.workRadius(-5, 45),
          throwsA(isA<GeometryValidationException>()));
    });

    test('length above maximum is rejected', () {
      expect(() => GeometryEngine.workRadius(999, 45),
          throwsA(isA<GeometryValidationException>()));
    });

    test('NaN length is rejected', () {
      expect(() => GeometryEngine.workRadius(double.nan, 45),
          throwsA(isA<GeometryValidationException>()));
    });

    test('infinite length is rejected', () {
      expect(() => GeometryEngine.workRadius(double.infinity, 45),
          throwsA(isA<GeometryValidationException>()));
    });
  });

  group('Invalid boom angle', () {
    test('negative angle is rejected', () {
      expect(() => GeometryEngine.workRadius(10, -1),
          throwsA(isA<GeometryValidationException>()));
    });

    test('angle above 90° is rejected', () {
      expect(() => GeometryEngine.workRadius(10, 90.0001),
          throwsA(isA<GeometryValidationException>()));
    });

    test('angle far above 90° is rejected', () {
      expect(() => GeometryEngine.workRadius(10, 180),
          throwsA(isA<GeometryValidationException>()));
    });

    test('boundary values 0° and 90° are accepted', () {
      expect(() => GeometryEngine.workRadius(10, 0), returnsNormally);
      expect(() => GeometryEngine.workRadius(10, 90), returnsNormally);
    });
  });

  group('Planning boundary  R_boundary = R + M', () {
    test('L=10, θ=0°, M=0 → 10.00 m', () {
      expect(GeometryEngine.boundaryRadius(10, 0, 0), closeTo(10.0, 1e-9));
    });

    test('L=10, θ=0°, M=2 → 12.00 m', () {
      expect(GeometryEngine.boundaryRadius(10, 0, 2), closeTo(12.0, 1e-9));
    });

    test('L=10, θ=60°, M=5 → 10.00 m', () {
      expect(GeometryEngine.boundaryRadius(10, 60, 5), closeTo(10.0, 1e-9));
    });

    test('L=10, θ=90°, M=3 → 3.00 m', () {
      expect(GeometryEngine.boundaryRadius(10, 90, 3), closeTo(3.0, 1e-9));
    });

    test('negative margin is rejected', () {
      expect(() => GeometryEngine.boundaryRadius(10, 45, -1),
          throwsA(isA<GeometryValidationException>()));
    });

    test('margin above maximum is rejected', () {
      expect(() => GeometryEngine.boundaryRadius(10, 45, 1000),
          throwsA(isA<GeometryValidationException>()));
    });
  });

  group('Full derivation (compute)', () {
    test('produces consistent work radius, boundary and tip height', () {
      final GeometryResult r = GeometryEngine.compute(
        boomLength: 30,
        boomAngleDegrees: 45,
        margin: 4,
      );
      expect(r.workRadius, closeTo(21.213, 0.001));
      expect(r.boundaryRadius, closeTo(25.213, 0.001));
      expect(r.boomTipHeight, closeTo(21.213, 0.001));
    });

    test('θ=0 → tip height is 0', () {
      final GeometryResult r = GeometryEngine.compute(
        boomLength: 12,
        boomAngleDegrees: 0,
        margin: 0,
      );
      expect(r.workRadius, closeTo(12.0, 1e-9));
      expect(r.boomTipHeight, closeTo(0.0, 1e-9));
    });

    test('θ=90 → work radius is 0 and tip height equals boom length', () {
      final GeometryResult r = GeometryEngine.compute(
        boomLength: 12,
        boomAngleDegrees: 90,
        margin: 2,
      );
      expect(r.workRadius, closeTo(0.0, 1e-9));
      expect(r.boomTipHeight, closeTo(12.0, 1e-9));
      expect(r.boundaryRadius, closeTo(2.0, 1e-9));
    });

    test('work radius is monotonically non-increasing in θ', () {
      double previous = double.infinity;
      for (double a = 0; a <= 90; a += 5) {
        final double r = GeometryEngine.workRadius(25, a);
        expect(r, lessThanOrEqualTo(previous + 1e-9));
        previous = r;
      }
    });
  });

  group('Validators', () {
    test('validateBoomLength accepts in-range values', () {
      expect(GeometryEngine.validateBoomLength(0.1), 0.1);
      expect(GeometryEngine.validateBoomLength(250), 250);
    });

    test('validateAngleDegrees accepts in-range values', () {
      expect(GeometryEngine.validateAngleDegrees(0), 0);
      expect(GeometryEngine.validateAngleDegrees(90), 90);
    });

    test('validateMargin accepts in-range values', () {
      expect(GeometryEngine.validateMargin(0), 0);
      expect(GeometryEngine.validateMargin(100), 100);
    });
  });
}
