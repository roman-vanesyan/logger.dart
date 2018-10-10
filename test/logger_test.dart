import "dart:async" show Future;

import "package:test/test.dart";
import "package:logger/logger.dart" show Logger, Level, Record;
import "package:logger/handlers.dart" show MemoryHandler;

void main() {
  group("Logger", () {
    test("Logger.getLogger returns the same logger for same name", () {
      final logger1 = Logger.getLogger("logger1");
      final logger2 = Logger.getLogger("logger1");
      final logger3 = Logger.getLogger("logger3");

      expect(logger1, same(logger2));
      expect(logger1, isNot(same(logger3)));
    });

    test("logger instantiated with Logger factory is not recoverable", () {
      final logger1 = Logger.getLogger("logger1");
      final logger2 = Logger(name: "logger2");
      final logger3 = Logger(name: "logger2");
      final logger4 = Logger(name: "logger4");
      final logger5 = Logger.getLogger("logger4");

      expect(logger1, isNot(same(logger2)));
      expect(logger2, isNot(same(logger3)));
      expect(logger4, isNot(same(logger5)));
    });

    test("loggers instantiated with Logger are not the same", () {
      final logger1 = Logger();
      final logger2 = Logger();
      final logger3 = Logger(name: "logger");
      final logger4 = Logger(name: "logger");

      expect(logger1, isNot(same(logger2)));
      expect(logger3, isNot(same(logger4)));

      logger3.close();
      logger4.close();
    });

    test("logger defaults", () {
      final logger = Logger();

      expect(logger.level, same(Level.info));
      expect(logger.name == "", isTrue);
    });

    test("Logger#level is set properly", () {
      final logger = Logger();

      expect(logger.level, same(Level.info));

      logger.level = Level.fatal;

      expect(logger.level, same(Level.fatal));

      logger.level = Level.debug;

      expect(logger.level, same(Level.debug));
    });

    test("Logger#level should throw on null", () {
      final logger = Logger();

      expect(() => logger.level = null, throwsArgumentError);

      logger.level = Level.all;

      expect(logger.level, same(Level.all));
    });

    test("Logger#name returns correct name of logger", () {
      final logger1 = Logger(name: "logger1");
      final logger2 = Logger.getLogger("logger2");

      expect(logger1.name, same("logger1"));
      expect(logger2.name, same("logger2"));

      logger2.close();
    });

    test("Logger#addHandler adds handlers correctly", () {
      final logger = Logger();
      final handler1 = MemoryHandler();
      final handler2 = MemoryHandler();

      logger.addHandler(handler1);
      logger.info("1");
      logger.fatal("2", die: false);
      logger.addHandler(handler2);
      logger.warning("3");
      logger.error("4");

      expect(handler1.records.length, equals(4));
      expect(handler2.records.length, equals(2));
    });

    test("Logger#log fires records in calls order", () {
      final logger = Logger(name: "logger1");
      final handler = MemoryHandler();
      List<Record> records;

      logger
        ..level = Level.all
        ..addHandler(handler);
      logger..log(Level.fatal, "1")..log(Level.info, "2")..log(Level.info, "3");

      records = handler.records;

      expect(records[0].message, equals("1"));
      expect(records[1].message, equals("2"));
      expect(records[2].message, equals("3"));

      logger..log(Level.debug, "4")..log(Level.error, "5");

      records = handler.records;

      expect(records[3].message, equals("4"));
      expect(records[4].message, equals("5"));
    });

    test(
        "Logger#log throws if either Level.all or Level.off is provided as level",
        () {
      final logger = Logger();
      final handler = MemoryHandler();

      logger.addHandler(handler);

      expect(() => logger.log(Level.all, "1"), throwsArgumentError);
      expect(() => logger.log(Level.off, "5"), throwsArgumentError);
    });

    test("Logger#log emits log records with custom severity", () {
      final logger = Logger();
      final handler = MemoryHandler();

      logger
        ..level = Level.all
        ..addHandler(handler);

      const customLevel = Level("custom", 0xff);

      logger.log(customLevel, "1");

      expect(handler.records.length, equals(1));
      expect(handler.records[0].level, equals(customLevel));
      expect(handler.records[0].message, equals("1"));
    });

    test("Logger#log throttles records with severity level less than set", () {
      final logger = Logger();
      final handler = MemoryHandler();
      List<Record> records;

      logger
        ..level = Level.info // explicitly set to `Level.info`
        ..addHandler(handler);

      logger.log(Level.info, "1");
      logger.log(Level.warning, "2");
      logger.log(Level.error, "3");
      logger.log(Level.fatal, "4");

      records = handler.records;

      expect(records.length, equals(4));

      const unloggableLevel = Level("unloggable", 0x1);
      const loggableLevel = Level("loggable", 0xf);

      logger.log(Level.debug, "5");
      logger.log(unloggableLevel, "6");
      logger.log(loggableLevel, "7");

      records = handler.records;

      expect(records.length, equals(5));
      expect(records[4].level, equals(loggableLevel));
    });

    test(
        "Logger severity level shotcuts methods are correctly set to"
        "corresponding severity levels", () {
      final logger = Logger();
      final handler = MemoryHandler();

      logger
        ..level = Level.all
        ..addHandler(handler);

      logger.debug("debug");
      logger.info("info");
      logger.warning("warning");
      logger.error("error");
      logger.fatal("fatal", die: false);

      final records = handler.records;

      expect(records.length, equals(5));
      expect(records[0].level, equals(Level.debug));
      expect(records[1].level, equals(Level.info));
      expect(records[2].level, equals(Level.warning));
      expect(records[3].level, equals(Level.error));
      expect(records[4].level, equals(Level.fatal));
    });

    test("Logger#close returns a future", () {
      final logger = Logger();
      final result = logger.close();

      expect(result is Future, isTrue);
    });

    test("Logger#close returns the same future as Logger#done", () {
      final logger = Logger();
      final result = logger.close();

      expect(result, same(logger.done));
    }, skip: true);

    test("isn't closed until Logger#close is called", () async {
      final logger = Logger();

      expect(logger.isClosed, isFalse);

      await logger.close();

      expect(logger.isClosed, isTrue);
    });
  });
}