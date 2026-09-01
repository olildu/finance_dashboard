import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_dashboard/features/budgets/presentation/category_pace_card.dart';

void main() {
  group('CategoryPaceCard', () {
    Widget createWidgetUnderTest({
      required Map<String, dynamic> status,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CategoryPaceCard(status: status),
          ),
        ),
      );
    }

    group('UI rendering', () {
      testWidgets('should render without crashing', (WidgetTester tester) async {
        // Arrange - real CategoryStatus-shaped data from backend
        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 1200.0,
          'remaining': 3800.0,
          'days_left': 25,
          'allowance_per_day': 152.0,
          'burn_rate_per_day': 120.0,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));

        // Assert
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });

      testWidgets('should display category display name when implemented',
          (WidgetTester tester) async {
        // Arrange
        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 1200.0,
          'remaining': 3800.0,
          'days_left': 25,
          'allowance_per_day': 152.0,
          'burn_rate_per_day': 120.0,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert - widget renders and has access to data
        expect(find.byType(CategoryPaceCard), findsOneWidget);
        // When implemented, this should display 'Food & Dining'
      });

      testWidgets('should display allowance per day value when implemented',
          (WidgetTester tester) async {
        // Arrange - real category status with specific allowance_per_day
        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 1200.0,
          'remaining': 3800.0,
          'days_left': 25,
          'allowance_per_day': 152.0,
          'burn_rate_per_day': 120.0,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert - widget renders with data available
        expect(find.byType(CategoryPaceCard), findsOneWidget);
        // When implemented, should display allowance_per_day (152.0)
      });

      testWidgets('should display burn rate per day value when implemented',
          (WidgetTester tester) async {
        // Arrange - real category status with specific burn_rate_per_day
        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 1200.0,
          'remaining': 3800.0,
          'days_left': 25,
          'allowance_per_day': 152.0,
          'burn_rate_per_day': 120.0,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert - widget renders with data available
        expect(find.byType(CategoryPaceCard), findsOneWidget);
        // When implemented, should display burn_rate_per_day (120.0)
      });

      testWidgets('should handle different category codes',
          (WidgetTester tester) async {
        // Arrange - different category
        final categoryStatus = {
          'category_code': 'transport',
          'display_name': 'Transportation',
          'budget': 2000.0,
          'spent': 800.0,
          'remaining': 1200.0,
          'days_left': 25,
          'allowance_per_day': 48.0,
          'burn_rate_per_day': 32.0,
          'projected_runout_date': '2024-10-15',
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CategoryPaceCard), findsOneWidget);
        // When implemented, should handle different categories properly
      });
    });

    group('data display', () {
      testWidgets('should handle all budget fields when implemented',
          (WidgetTester tester) async {
        // Arrange
        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 1200.0,
          'remaining': 3800.0,
          'days_left': 25,
          'allowance_per_day': 152.0,
          'burn_rate_per_day': 120.0,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert - widget renders with all data available
        expect(find.byType(CategoryPaceCard), findsOneWidget);
        // When implemented, should use all these fields
      });

      testWidgets('should work with decimal budget amounts',
          (WidgetTester tester) async {
        // Arrange
        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.50,
          'spent': 1200.75,
          'remaining': 3799.75,
          'days_left': 25,
          'allowance_per_day': 151.99,
          'burn_rate_per_day': 120.03,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert - widget renders with decimal data
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });

      testWidgets('should work with large category lists',
          (WidgetTester tester) async {
        // Arrange - test with larger amount
        final categoryStatus = {
          'category_code': 'travel_party',
          'display_name': 'Travel & Party Outside',
          'budget': 50000.0,
          'spent': 15000.0,
          'remaining': 35000.0,
          'days_left': 25,
          'allowance_per_day': 1400.0,
          'burn_rate_per_day': 600.0,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert - widget renders with large values
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });

      testWidgets('should handle decimal precision in metrics',
          (WidgetTester tester) async {
        // Arrange - test with decimal values
        final categoryStatus = {
          'category_code': 'shopping',
          'display_name': 'Shopping',
          'budget': 3000.0,
          'spent': 500.50,
          'remaining': 2499.50,
          'days_left': 20,
          'allowance_per_day': 124.975,
          'burn_rate_per_day': 25.025,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert - should handle decimal precision
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });
    });

    group('pace metrics', () {
      testWidgets('should render allowance per day metric when implemented',
          (WidgetTester tester) async {
        // Arrange
        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 1200.0,
          'remaining': 3800.0,
          'days_left': 25,
          'allowance_per_day': 152.0,
          'burn_rate_per_day': 120.0,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert - widget renders with metric available
        expect(find.byType(CategoryPaceCard), findsOneWidget);
        // When implemented, should display allowance_per_day (152.0)
      });

      testWidgets('should render burn rate metric when implemented',
          (WidgetTester tester) async {
        // Arrange
        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 1200.0,
          'remaining': 3800.0,
          'days_left': 25,
          'allowance_per_day': 152.0,
          'burn_rate_per_day': 120.0,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert - widget renders with metric available
        expect(find.byType(CategoryPaceCard), findsOneWidget);
        // When implemented, should display burn_rate_per_day (120.0)
      });

      testWidgets('should handle zero allowance per day',
          (WidgetTester tester) async {
        // Arrange - category with no remaining budget (overspent)
        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 6000.0,
          'remaining': 0.0,
          'days_left': 25,
          'allowance_per_day': 0.0,
          'burn_rate_per_day': 240.0,
          'projected_runout_date': '2024-09-05',
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert - should render without crashing
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });

      testWidgets('should handle zero burn rate per day',
          (WidgetTester tester) async {
        // Arrange - category with no spending yet
        final categoryStatus = {
          'category_code': 'entertainment',
          'display_name': 'Entertainment',
          'budget': 1000.0,
          'spent': 0.0,
          'remaining': 1000.0,
          'days_left': 25,
          'allowance_per_day': 40.0,
          'burn_rate_per_day': 0.0,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert - should render without crashing
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });

      testWidgets('should handle high burn rate', (WidgetTester tester) async {
        // Arrange - category with high daily spend
        final categoryStatus = {
          'category_code': 'travel_party',
          'display_name': 'Travel & Party Outside',
          'budget': 10000.0,
          'spent': 3500.0,
          'remaining': 6500.0,
          'days_left': 20,
          'allowance_per_day': 325.0,
          'burn_rate_per_day': 175.0,
          'projected_runout_date': '2024-10-08',
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert - should render without crashing
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });
    });

    group('projected runout date', () {
      testWidgets('should handle null projected_runout_date',
          (WidgetTester tester) async {
        // Arrange
        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 1200.0,
          'remaining': 3800.0,
          'days_left': 25,
          'allowance_per_day': 152.0,
          'burn_rate_per_day': 120.0,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert - should render without crashing
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });

      testWidgets('should handle projected_runout_date string',
          (WidgetTester tester) async {
        // Arrange
        final categoryStatus = {
          'category_code': 'transport',
          'display_name': 'Transportation',
          'budget': 2000.0,
          'spent': 800.0,
          'remaining': 1200.0,
          'days_left': 25,
          'allowance_per_day': 48.0,
          'burn_rate_per_day': 32.0,
          'projected_runout_date': '2024-10-15',
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert - should display the date if shown
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });
    });

    group('category code handling', () {
      testWidgets('should handle food category code',
          (WidgetTester tester) async {
        // Arrange
        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 1200.0,
          'remaining': 3800.0,
          'days_left': 25,
          'allowance_per_day': 152.0,
          'burn_rate_per_day': 120.0,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });

      testWidgets('should handle transport category code',
          (WidgetTester tester) async {
        // Arrange
        final categoryStatus = {
          'category_code': 'transport',
          'display_name': 'Transportation',
          'budget': 2000.0,
          'spent': 800.0,
          'remaining': 1200.0,
          'days_left': 25,
          'allowance_per_day': 48.0,
          'burn_rate_per_day': 32.0,
          'projected_runout_date': '2024-10-15',
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });

      testWidgets('should handle travel_party category code',
          (WidgetTester tester) async {
        // Arrange
        final categoryStatus = {
          'category_code': 'travel_party',
          'display_name': 'Travel & Party Outside',
          'budget': 10000.0,
          'spent': 3500.0,
          'remaining': 6500.0,
          'days_left': 20,
          'allowance_per_day': 325.0,
          'burn_rate_per_day': 175.0,
          'projected_runout_date': '2024-10-08',
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('should handle very small remaining amount',
          (WidgetTester tester) async {
        // Arrange
        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 4999.99,
          'remaining': 0.01,
          'days_left': 25,
          'allowance_per_day': 0.0004,
          'burn_rate_per_day': 199.996,
          'projected_runout_date': '2024-09-02',
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });

      testWidgets('should handle first day of month',
          (WidgetTester tester) async {
        // Arrange - first day: 30 days left in 30-day month
        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 0.0,
          'remaining': 5000.0,
          'days_left': 30,
          'allowance_per_day': 166.67,
          'burn_rate_per_day': 0.0,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });

      testWidgets('should handle last day of month', (WidgetTester tester) async {
        // Arrange - last day: 1 day left
        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 4500.0,
          'remaining': 500.0,
          'days_left': 1,
          'allowance_per_day': 500.0,
          'burn_rate_per_day': 4500.0,
          'projected_runout_date': '2024-09-30',
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });
    });

    group('responsive design', () {
      testWidgets('should render on small screen', (WidgetTester tester) async {
        // Arrange
        tester.binding.window.physicalSizeTestValue = const Size(400, 600);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 1200.0,
          'remaining': 3800.0,
          'days_left': 25,
          'allowance_per_day': 152.0,
          'burn_rate_per_day': 120.0,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));

        // Assert
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });

      testWidgets('should render on large screen', (WidgetTester tester) async {
        // Arrange
        tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        final categoryStatus = {
          'category_code': 'food',
          'display_name': 'Food & Dining',
          'budget': 5000.0,
          'spent': 1200.0,
          'remaining': 3800.0,
          'days_left': 25,
          'allowance_per_day': 152.0,
          'burn_rate_per_day': 120.0,
          'projected_runout_date': null,
        };

        // Act
        await tester.pumpWidget(createWidgetUnderTest(status: categoryStatus));

        // Assert
        expect(find.byType(CategoryPaceCard), findsOneWidget);
      });
    });
  });
}
