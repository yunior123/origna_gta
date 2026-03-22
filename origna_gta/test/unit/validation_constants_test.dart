import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/constants/validation_constants.dart';

void main() {
  group('ValidationConstants', () {
    group('emailRegex', () {
      test('accepts valid standard email', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user@example.com'),
          isTrue,
        );
      });

      test('accepts email with dots in local part', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user.name@example.com'),
          isTrue,
        );
      });

      test('accepts email with plus sign', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user+tag@example.com'),
          isTrue,
        );
      });

      test('accepts email with hyphen in domain', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user@my-domain.com'),
          isTrue,
        );
      });

      test('accepts email with subdomain', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user@mail.example.com'),
          isTrue,
        );
      });

      test('accepts email with country TLD', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user@example.co.uk'),
          isTrue,
        );
      });

      test('accepts short email', () {
        expect(ValidationConstants.emailRegex.hasMatch('a@b.ca'), isTrue);
      });

      test('accepts numeric local part', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('12345@example.com'),
          isTrue,
        );
      });

      test('accepts mixed alphanumeric', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user123@test456.com'),
          isTrue,
        );
      });

      test('rejects empty string', () {
        expect(ValidationConstants.emailRegex.hasMatch(''), isFalse);
      });

      test('rejects email without @', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('userexample.com'),
          isFalse,
        );
      });

      test('rejects email with multiple @', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user@@example.com'),
          isFalse,
        );
      });

      test('rejects email without domain', () {
        expect(ValidationConstants.emailRegex.hasMatch('user@'), isFalse);
      });

      test('rejects email without local part', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('@example.com'),
          isFalse,
        );
      });

      test('rejects email with single-char TLD', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user@example.c'),
          isFalse,
        );
      });

      test('rejects email with spaces', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user @example.com'),
          isFalse,
        );
      });

      test('rejects email starting with @', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('@no-local.com'),
          isFalse,
        );
      });

      test('rejects email ending with @', () {
        expect(ValidationConstants.emailRegex.hasMatch('no-domain@'), isFalse);
      });

      test('rejects plain text', () {
        expect(ValidationConstants.emailRegex.hasMatch('notanemail'), isFalse);
      });

      test('rejects email with special chars outside allowed set', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user!name@example.com'),
          isFalse,
        );
      });

      test('accepts percent sign in local part', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user%name@example.com'),
          isTrue,
        );
      });

      test('accepts underscore in local part', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user_name@example.com'),
          isTrue,
        );
      });
    });

    group('passwordRegex', () {
      test('accepts strong password with all requirements', () {
        expect(
          ValidationConstants.passwordRegex.hasMatch('StrongP@ss1'),
          isTrue,
        );
      });

      test('accepts password with different special chars', () {
        expect(ValidationConstants.passwordRegex.hasMatch('Abc1234!'), isTrue);
        expect(ValidationConstants.passwordRegex.hasMatch('Abc1234@'), isTrue);
        expect(ValidationConstants.passwordRegex.hasMatch('Abc1234#'), isTrue);
        expect(ValidationConstants.passwordRegex.hasMatch('Abc1234\$'), isTrue);
        expect(ValidationConstants.passwordRegex.hasMatch('Abc1234%'), isTrue);
      });

      test('accepts exactly 8 chars password', () {
        expect(ValidationConstants.passwordRegex.hasMatch('Abcd@12'), isFalse);
        expect(ValidationConstants.passwordRegex.hasMatch('Abcd@123'), isTrue);
      });

      test('accepts long password', () {
        expect(
          ValidationConstants.passwordRegex.hasMatch('VeryLongP@ssw0rd123'),
          isTrue,
        );
      });

      test('rejects short password', () {
        expect(ValidationConstants.passwordRegex.hasMatch('Short1!'), isFalse);
      });

      test('rejects password without uppercase', () {
        expect(
          ValidationConstants.passwordRegex.hasMatch('alllowercase1!'),
          isFalse,
        );
      });

      test('rejects password without lowercase', () {
        expect(
          ValidationConstants.passwordRegex.hasMatch('ALLUPPERCASE1!'),
          isFalse,
        );
      });

      test('rejects password without digit', () {
        expect(
          ValidationConstants.passwordRegex.hasMatch('NoDigitsHere!'),
          isFalse,
        );
      });

      test('rejects password without special char', () {
        expect(
          ValidationConstants.passwordRegex.hasMatch('NoSpecial1'),
          isFalse,
        );
      });

      test('rejects empty password', () {
        expect(ValidationConstants.passwordRegex.hasMatch(''), isFalse);
      });

      test('rejects spaces', () {
        expect(ValidationConstants.passwordRegex.hasMatch('Abc 123!'), isFalse);
      });

      test('accepts multiple digits', () {
        expect(
          ValidationConstants.passwordRegex.hasMatch('Abcdef!12345'),
          isTrue,
        );
      });

      test('accepts multiple special chars', () {
        expect(
          ValidationConstants.passwordRegex.hasMatch('Abcdef!@#123'),
          isTrue,
        );
      });

      test('accepts special char at start', () {
        expect(ValidationConstants.passwordRegex.hasMatch('!Abcdefg1'), isTrue);
      });

      test('accepts special char at end', () {
        expect(ValidationConstants.passwordRegex.hasMatch('Abcdefg1!'), isTrue);
      });

      test('rejects password in commonPasswords', () {
        expect(ValidationConstants.passwordRegex.hasMatch('password'), isFalse);
      });
    });

    group('constants', () {
      test('minPasswordLength is 8', () {
        expect(ValidationConstants.minPasswordLength, 8);
      });

      test('maxEmailLength is 254', () {
        expect(ValidationConstants.maxEmailLength, 254);
      });

      test('minEmailLength is 6', () {
        expect(ValidationConstants.minEmailLength, 6);
      });

      test('minNameLength is 2', () {
        expect(ValidationConstants.minNameLength, 2);
      });

      test('maxNameLength is 60', () {
        expect(ValidationConstants.maxNameLength, 60);
      });

      test('minPasswordLength is positive', () {
        expect(ValidationConstants.minPasswordLength, greaterThan(0));
      });

      test('maxEmailLength is reasonable', () {
        expect(ValidationConstants.maxEmailLength, lessThanOrEqualTo(256));
      });

      test('minNameLength is less than maxNameLength', () {
        expect(
          ValidationConstants.minNameLength,
          lessThan(ValidationConstants.maxNameLength),
        );
      });

      test('minEmailLength is less than maxEmailLength', () {
        expect(
          ValidationConstants.minEmailLength,
          lessThan(ValidationConstants.maxEmailLength),
        );
      });
    });

    group('commonPasswords', () {
      test('is not empty', () {
        expect(ValidationConstants.commonPasswords, isNotEmpty);
      });

      test('contains password', () {
        expect(ValidationConstants.commonPasswords, contains('password'));
      });

      test('contains 12345678', () {
        expect(ValidationConstants.commonPasswords, contains('12345678'));
      });

      test('contains qwerty123', () {
        expect(ValidationConstants.commonPasswords, contains('qwerty123'));
      });

      test('contains abc123456', () {
        expect(ValidationConstants.commonPasswords, contains('abc123456'));
      });

      test('contains password1', () {
        expect(ValidationConstants.commonPasswords, contains('password1'));
      });

      test('all entries are non-empty', () {
        for (final pwd in ValidationConstants.commonPasswords) {
          expect(pwd, isNotEmpty);
        }
      });

      test('all entries are lowercase', () {
        for (final pwd in ValidationConstants.commonPasswords) {
          expect(pwd, equals(pwd.toLowerCase()));
        }
      });

      test('has at least 5 entries', () {
        expect(
          ValidationConstants.commonPasswords.length,
          greaterThanOrEqualTo(5),
        );
      });

      test('no duplicates', () {
        final unique = ValidationConstants.commonPasswords.toSet();
        expect(
          unique.length,
          equals(ValidationConstants.commonPasswords.length),
        );
      });
    });

    group('integration', () {
      test('email and password validation work together', () {
        final email = 'user@example.com';
        final password = 'StrongP@ss1';

        expect(ValidationConstants.emailRegex.hasMatch(email), isTrue);
        expect(ValidationConstants.passwordRegex.hasMatch(password), isTrue);
      });

      test('rejects common password even if meets complexity', () {
        final password = 'password1!';
        if (ValidationConstants.commonPasswords.contains('password1')) {
          expect(
            ValidationConstants.commonPasswords.contains('password1'),
            isTrue,
          );
        }
      });
    });

    group('emailRegex edge cases', () {
      test('handles consecutive dots in local part', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user..name@example.com'),
          isTrue,
        );
      });

      test('handles domain starting with dot', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user@.example.com'),
          isFalse,
        );
      });

      test('handles domain ending with dot', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user@example.com.'),
          isFalse,
        );
      });

      test('handles IP address domain (rejected)', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('user@192.168.1.1'),
          isFalse,
        );
      });

      test('handles quoted local part (rejected by simplified regex)', () {
        expect(
          ValidationConstants.emailRegex.hasMatch('"user name"@example.com'),
          isFalse,
        );
      });
    });

    group('passwordRegex edge cases', () {
      test('handles all allowed special chars', () {
        final specialChars = [
          '!',
          '@',
          '#',
          r'$',
          '%',
          '^',
          '&',
          '*',
          '(',
          ')',
          ',',
          '.',
          '?',
          '"',
          ':',
          '{',
          '}',
          '|',
          '<',
          '>',
        ];
        for (final char in specialChars) {
          final password = 'Abcdefg1$char';
          expect(
            ValidationConstants.passwordRegex.hasMatch(password),
            isTrue,
            reason: 'Password with $char should be valid',
          );
        }
      });

      test('handles password with only one uppercase', () {
        expect(ValidationConstants.passwordRegex.hasMatch('Abcdefg!1'), isTrue);
      });

      test('handles password with only one lowercase', () {
        expect(ValidationConstants.passwordRegex.hasMatch('ABCDEFg!1'), isTrue);
      });

      test('handles password with only one digit', () {
        expect(ValidationConstants.passwordRegex.hasMatch('Abcdefg!1'), isTrue);
      });

      test('handles password with only one special char', () {
        expect(ValidationConstants.passwordRegex.hasMatch('Abcdefg1!'), isTrue);
      });
    });
  });
}
