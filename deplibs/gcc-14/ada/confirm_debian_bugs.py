#!/usr/bin/python3

# Helper when migrating bugs from a gnat version to another.

# Attempt to reproduce each known GNAT bug with version BV.
# Reports results as control@bugs.debian.org commands.
# Only remove temporary subdirectories when the bug is reproduced.

# python3 confirm_debian_bugs.py same BV            -> found    | fixed
# python3 confirm_debian_bugs.py new  BV            -> reassign | retitle

# flake8 confirm_debian_bugs.py
# pylint confirm_debian_bugs.py
# mypy confirm_debian_bugs.py
# rm -fr .mypy_cache/

# pylint: disable=too-many-lines
# pylint: disable=missing-module-docstring
# pylint: disable=missing-function-docstring

import os.path
import re
import shutil
import subprocess
import sys
import tempfile
import typing

Make: typing.TypeAlias = typing.Sequence[str]
Sources: typing.TypeAlias = typing.Iterable[tuple[str, str]]

os.environ['LC_ALL'] = 'C'

assert len(sys.argv) == 3, 'expected same|new new_version'
assert sys.argv[1] in ("same", "new")
SAME_GCC_BASE_VERSION = sys.argv[1] == "same"
new_version = sys.argv[2]

for line in subprocess.check_output(
        ("dpkg", "--status", f"gnat-{new_version}")).decode().split("\n"):
    if line.startswith("Version: "):
        deb_version = line[len("Version: "):]
        break
# Will cause an error later if deb_version is not defined.

# Each bug has its own subdirectory in WORKSPACE.
# Every bug subdir is removed if the bug is confirmed,
# and WORKSPACE is removed if empty.
workspace = tempfile.mkdtemp(suffix=f"-gnat-{new_version}-bugs")


def attempt_to_reproduce(bug: int,
                         make: Make,
                         sources: Sources,
                         ) -> tuple[str, int, str]:
    tmp_dir = os.path.join(workspace, f"bug{bug}")
    os.mkdir(tmp_dir)

    for (name, contents) in sources:
        with open(os.path.join(tmp_dir, name), "w", encoding="UTF-8") as out_f:
            out_f.write(contents)

    path = os.path.join(tmp_dir, "stderr.log")
    with open(path, "w", encoding="UTF-8") as out_f:
        status = subprocess.call(make, stderr=out_f, cwd=tmp_dir)
    with open(path, "r", encoding="UTF-8") as in_f:
        stderr = in_f.read()
    return tmp_dir, status, stderr


def reassign_and_remove_dir(bug: int, tmp_dir: str) -> None:
    if SAME_GCC_BASE_VERSION:
        print(f"found {bug} {deb_version}")
    else:
        print(f"reassign {bug} gnat-{new_version} {deb_version}")
    shutil.rmtree(tmp_dir)


def report(bug: int, message: str, output: str) -> None:
    print(f"# {bug}: {message}.")
    for report_line in output.split("\n"):
        print(f"# {report_line}")


def report_and_retitle(bug: int, message: str, output: str) -> None:
    report(bug, message, output)
    if SAME_GCC_BASE_VERSION:
        print(f"fixed {bug} {deb_version}")
    else:
        print(f"retitle {bug} [Fixed in {new_version}] <current title>")


def check_compiles_but_should_not(bug: int,
                                  make: Make,
                                  sources: Sources,
                                  ) -> None:
    tmp_dir, status, stderr = attempt_to_reproduce(bug, make, sources)
    if status == 0:
        reassign_and_remove_dir(bug, tmp_dir)
    else:
        report_and_retitle(bug, "now fails to compile (bug is fixed?)", stderr)


def check_reports_an_error_but_should_not(bug: int,
                                          make: Make,
                                          sources: Sources,
                                          regex: str,
                                          ) -> None:
    tmp_dir, status, stderr = attempt_to_reproduce(bug, make, sources)
    if status == 0:
        report_and_retitle(bug, "now compiles (bug is fixed?)", stderr)
    elif re.search(regex, stderr):
        reassign_and_remove_dir(bug, tmp_dir)
    else:
        report(bug, "still fails to compile, but with a new stderr", stderr)


def check_reports_error_but_forgets_one(bug: int,
                                        make: Make,
                                        sources: Sources,
                                        regex: str,
                                        ) -> None:
    tmp_dir, status, stderr = attempt_to_reproduce(bug, make, sources)
    if status == 0:
        report(bug, "now compiles (?)", stderr)
    elif re.search(regex, stderr):
        report_and_retitle(bug, "now reports the error (bug is fixed ?)",
                           stderr)
    else:
        reassign_and_remove_dir(bug, tmp_dir)


def check_produces_a_faulty_executable(bug: int,
                                       make: Make,
                                       sources: Sources,
                                       regex: str,
                                       trigger: str,
                                       ) -> None:
    tmp_dir, status, stderr = attempt_to_reproduce(bug, make, sources)
    if status != 0:
        report(bug, "cannot compile the trigger anymore", stderr)
    else:
        output = subprocess.check_output((os.path.join(tmp_dir, trigger), ),
                                         cwd=tmp_dir).decode()
        if re.search(regex, output):
            reassign_and_remove_dir(bug, tmp_dir)
        else:
            report_and_retitle(bug,
                               "output of the trigger changed (bug fixed?)",
                               output)


######################################################################

check_reports_an_error_but_should_not(
    bug=244936,
    make=(f"gnatmake-{new_version}", "p"),
    regex='p[.]ads:3:25: error: '
    '"foo" is hidden within declaration of instance',
    sources=(
        ("foo.ads", """generic
procedure foo;
"""),
        ("foo.adb", """procedure foo is
begin
   null;
end foo;
"""), ("p.ads", """with foo;
package p is
   procedure FOO is new foo;        -- OK
end p;
""")))

check_compiles_but_should_not(
    bug=244970,
    make=(f"gnatmake-{new_version}", "pak5"),
    sources=(
        ("pak1.ads", """generic
package pak1 is
end pak1;
"""),
        ("pak1-pak2.ads", """generic
package pak1.pak2 is
end pak1.pak2;
"""),
        ("pak5.ads", """with pak1.pak2;
generic
   with package new_pak2 is new pak1.pak2;  -- ERROR: illegal use of pak1
package pak5 is
end pak5;
""")))

check_reports_an_error_but_should_not(
    bug=246187,
    make=(f"gnatmake-{new_version}", "test_43"),
    regex="Error detected at test_43.ads:11:4",
    sources=(
        ("test_43.ads", """package Test_43 is
  type T1 is private;

private

   type T2 is record
      a: T1;
   end record;
   type T2_Ptr is access T2;

   type T1 is record
      n: T2_Ptr := new T2;
   end record;

end Test_43;
"""),))

check_compiles_but_should_not(
    bug=247013,
    make=(f"gnatmake-{new_version}", "test_53"),
    sources=(
        ("test_53.ads", """generic
   type T1 is private;
package Test_53 is
   type T2 (x: integer) is new T1;  -- ERROR: x not used
end Test_53;
"""),))

check_compiles_but_should_not(
    bug=247017,
    make=(f"gnatmake-{new_version}", "test_59"),
    sources=(
        ("test_59.adb", """procedure Test_59 is

    generic
       type T1 (<>) is private;
    procedure p1(x: out T1);

    procedure p1 (x: out T1) is
    b: boolean := x'constrained;   --ERROR: not a discriminated type
    begin
       null;
    end p1;

begin
   null;
end Test_59;
"""),))

check_compiles_but_should_not(
    bug=247018,
    make=(f"gnatmake-{new_version}", "test_60"),
    sources=(
        ("pak1.ads", """package pak1 is
   generic
   package pak2 is
   end pak2;
end pak1;
"""),
        ("test_60.ads", """with pak1;
package Test_60 is
   package PAK1 is new pak1.pak2;   --ERROR: illegal reference to pak1
end Test_60;
""")))

check_compiles_but_should_not(
    bug=247019,
    make=(f"gnatmake-{new_version}", "test_61"),
    sources=(
        ("test_61.adb", """procedure Test_61 is
   procedure p1;

   generic
   package pak1 is
      procedure p2 renames p1;
   end pak1;

   package new_pak1 is new pak1;
   procedure p1 renames new_pak1.p2;   --ERROR: circular renames
begin
   p1;
end Test_61;
"""),))

check_produces_a_faulty_executable(
    bug=247569,
    make=(f"gnatmake-{new_version}", "test_75"),
    trigger="test_75",
    regex="failed: wrong p1 called",
    sources=(
        ("test_75.adb", """with text_io;
procedure Test_75 is
   generic
   package pak1 is
      type T1 is null record;
   end pak1;

   generic
      with package A is new pak1(<>);
      with package B is new pak1(<>);
   package pak2 is
      procedure p1(x: B.T1);
      procedure p1(x: A.T1);
   end pak2;

   package body pak2 is

      procedure p1(x: B.T1) is
      begin
         text_io.put_line("failed: wrong p1 called");
      end p1;

      procedure p1(x: A.T1) is
      begin
         text_io.put_line("passed");
      end p1;

      x: A.T1;
   begin
      p1(x);
   end pak2;

   package new_pak1 is new pak1;
   package new_pak2 is new pak2(new_pak1, new_pak1); -- (1)

begin
   null;
end Test_75;
"""),))

check_compiles_but_should_not(
    bug=247570,
    make=(f"gnatmake-{new_version}", "test_76"),
    sources=(
        ("test_76.adb", """procedure Test_76 is

   generic
   procedure p1;

   pragma Convention (Ada, p1);

   procedure p1 is
   begin
      null;
   end p1;

   procedure new_p1 is new p1;
   pragma Convention (Ada, new_p1);    --ERROR: new_p1 already frozen

begin
   null;
end Test_76;
"""),))

check_produces_a_faulty_executable(
    bug=247571,
    make=(f"gnatmake-{new_version}", "test_77"),
    trigger="test_77",
    regex="failed: wrong p1 called",
    sources=(
        ("pak.ads", """package pak is
   procedure p1;
   procedure p1(x: integer);
   pragma export(ada, p1);
end pak;
"""),
        ("pak.adb", """with text_io; use text_io;
package body pak is
   procedure p1 is
   begin
      put_line("passed");
   end;

   procedure p1(x: integer) is
   begin
      put_line("failed: wrong p1 called");
   end;
end pak;
"""),
        ("test_77.adb", """with pak;
procedure Test_77 is
   procedure p1;
   pragma import(ada, p1);
begin
   p1;
end Test_77;
""")))

check_compiles_but_should_not(
    bug=248166,
    make=(f"gnatmake-{new_version}", "test_82"),
    sources=(
        ("test_82.adb", """procedure Test_82 is
   package pak1 is
      type T1 is tagged null record;
   end pak1;

   package body pak1 is
      -- type T1 is tagged null record;  -- line 7

      function "=" (x, y : T1'class) return boolean is -- line 9
      begin
         return true;
      end "=";

      procedure proc (x, y : T1'class) is
         b : boolean;
      begin
         b := x = y;     --ERROR: ambiguous "="
      end proc;

   end pak1;

begin
   null;
end Test_82;
"""),))

check_compiles_but_should_not(
    bug=248168,
    make=(f"gnatmake-{new_version}", "test_84"),
    sources=(
        ("test_84.adb", """procedure Test_84 is
   package pak1 is
      type T1 is abstract tagged null record;
      procedure p1(x: in out T1) is abstract;
   end pak1;

   type T2 is new pak1.T1 with null record;

   protected type T3 is
   end T3;

   protected body T3 is
   end T3;

   procedure p1(x: in out T2) is    --ERROR: declared after body of T3
   begin
      null;
   end p1;

begin
   null;
end Test_84;
"""),))

check_compiles_but_should_not(
    bug=248678,
    make=(f"gnatmake-{new_version}", "test_80"),
    sources=(
        ("test_80.ads", """package Test_80 is
   generic
      type T1(<>) is private;
      with function "=" (Left, Right : T1) return Boolean is <>;
   package pak1 is
   end pak1;

   package pak2 is
      type T2 is abstract tagged null record;
      package new_pak1 is new pak1 (T2'Class);  --ERROR: no matching "="
   end pak2;
end Test_80;
"""),))

check_compiles_but_should_not(
    bug=248681,
    make=(f"gnatmake-{new_version}", "test_91"),
    sources=(
        ("test_91.adb", """--  RM 8.5.4(5)
--  ...the convention of the renamed subprogram shall not be
--  Intrinsic.
with unchecked_deallocation;
procedure Test_91 is
   generic -- when non generic, we get the expected error
   package pak1 is
      type int_ptr is access integer;
      procedure free(x: in out int_ptr);
   end pak1;

   package body pak1 is
      procedure deallocate is new
        unchecked_deallocation(integer, int_ptr);
      procedure free(x: in out int_ptr) renames
        deallocate;  --ERROR: renaming as body can't rename intrinsic
   end pak1;
begin
   null;
end Test_91;
"""),))

check_compiles_but_should_not(
    bug=248682,
    make=(f"gnatmake-{new_version}", "main"),
    sources=(
        ("main.adb", """--  RM 6.3.1(9)
--  The default calling convention is Intrinsic for ...  an attribute
--  that is a subprogram;

--  RM 8.5.4(5)
--  ...the convention of the renamed subprogram shall not be
--  Intrinsic.
procedure main is
   package pak1 is
      function f1(x: integer'base) return integer'base;
   end pak1;

   package body pak1 is
      function f1(x: integer'base) return integer'base renames
        integer'succ;  --ERROR: renaming as body can't rename intrinsic
   end pak1;
begin
   null;
end;
"""),))

check_reports_an_error_but_should_not(
    bug=253737,
    make=(f"gnatmake-{new_version}", "test_4"),
    regex='test_4[.]ads:3:01: error: "pak2" not declared in "pak1"',
    sources=(
        ("parent.ads", """generic
package parent is
end parent;
"""),
        ("parent-pak2.ads", """generic
package parent.pak2 is
end parent.pak2;
"""),
        ("parent-pak2-pak3.ads", """generic
package parent.pak2.pak3 is
end parent.pak2.pak3;
"""),
        ("parent-pak2-pak4.ads", """with parent.pak2.pak3;
generic
package parent.pak2.pak4 is
   package pak3 is new parent.pak2.pak3;
end parent.pak2.pak4;
"""),
        ("pak1.ads", """with parent;
package pak1 is new parent;
"""),
        ("pak6.ads", """with parent.pak2;
with pak1;
package pak6 is new pak1.pak2;
"""),
        ("test_4.ads", """with parent.pak2.pak4;
with pak6;
package Test_4 is new pak6.pak4;
""")))

check_compiles_but_should_not(
    bug=269948,
    make=(f"gnatmake-{new_version}", "test_119"),
    sources=(
        ("test_119.ads", """
--  RM 3.9.3/11 A generic actual subprogram shall not be an abstract
--  subprogram.  works OK if unrelated line (A) is commented out.
package Test_119 is
   generic
      with function "=" (X, Y : integer) return Boolean is <>;
      -- Removing this allows GCC to detect the problem.
   package pak1 is
      function "=" (X, Y: float) return Boolean is abstract;
      generic
         with function Equal (X, Y : float) return Boolean is "=";  --ERROR:
      package pak2 is
      end pak2;
   end pak1;

   package new_pak1 is new pak1;
   package new_pak2 is new new_pak1.pak2;
end Test_119;
"""),))

check_compiles_but_should_not(
    bug=269951,
    make=(f"gnatmake-{new_version}", "test_118"),
    sources=(
        ("pak1.ads", """generic
package pak1 is
end pak1;
"""),
        ("pak1-foo.ads", """generic
package pak1.foo is
end pak1.foo;
"""),
        ("test_118.ads", """with pak1.foo;
package Test_118 is
   package pak3 is
      foo: integer;
   end pak3;
   use pak3;

   package new_pak1 is new pak1;
   use new_pak1;

   x: integer := foo;       -- ERROR: foo hidden by use clauses
end Test_118;
"""),))

# As long as 24:14 is detected, it inhibits detection of 25:21.
check_reports_error_but_forgets_one(
    bug=276224,
    make=(f"gnatmake-{new_version}", "test_121"),
    regex="test_121[.]adb:25:21: dynamically tagged expression not allowed",
    sources=(
        ("test_121.adb",
         """--  If the expected type for an expression or name is some specific
--  tagged type, then the expression or name shall not be dynamically
--  tagged unless it is a controlling operand in a call on a
--  dispatching operation.
procedure Test_121 is
   package pak1 is
      type T1 is tagged null record;
      function f1 (x1: T1) return T1;
   end pak1;

   package body pak1 is
      function f1 (x1: T1) return T1 is
      begin
         return x1;
      end;
   end pak1;
   use pak1;

   type T2 is record
      a1: T1;
   end record;

   z0: T1'class := T1'(null record);
   z1: T1 := f1(z0);           -- ERROR: gnat correctly rejects
   z2: T2 := (a1 => f1(z0));   -- ERROR: gnat mistakenly allows
begin
   null;
end Test_121;
"""),))

check_reports_an_error_but_should_not(
    bug=276227,
    make=(f"gnatmake-{new_version}", "test_124"),
    regex='test_124[.]ads:6:35: error: '
    'size for "T_arr_constrained" too small, minimum allowed is 256',
    sources=(
        ("test_124.ads", """package Test_124 is
   type T is range 1 .. 32;
   type T_arr_unconstrained is array (T range <>) of boolean;
   type T_arr_constrained is new T_arr_unconstrained (T);
   pragma pack (T_arr_unconstrained);
   for T_arr_constrained'size use 32;
end Test_124;
"""),))

check_reports_an_error_but_should_not(
    bug=278687,
    make=(f"gnatmake-{new_version}", "test_127"),
    regex='test_127[.]adb:10:21: error: expected type "T2" defined at line 4',
    sources=(
        ("test_127.ads",
         """-- The second parameter of T2'Class'Read is of type T2'Class,
-- which should match an object of type T3, which is derived
-- from T2.
package test_127 is
   pragma elaborate_body;
end test_127;
"""),
        ("test_127.adb", """with ada.streams;
package body test_127 is
   type T1 is access all ada.streams.root_stream_type'class;
   type T2 is tagged null record;
   type T3 is new T2 with null record;

   x: T1;
   y: T3;
begin
   T2'class'read(x, y);
end test_127;
""")))

check_compiles_but_should_not(
    bug=278831,
    make=(f"gnatmake-{new_version}", "test_128"),
    sources=(
        ("test_128.ads", """package Test_128 is
   package inner is
   private
      type T1;
   end inner;
   type T1_ptr is access inner.T1; -- line  9 ERROR: gnat mistakenly accepts
end Test_128;
"""),
        ("test_128.adb", """package body test_128 is
   package body inner is
      type T1 is new Integer;
   end inner;
end Test_128;
""")))

# Note that we also check the absence of the next inhibited message.
check_reports_an_error_but_should_not(
    bug=279893,
    make=(f"gnatmake-{new_version}", "test_129"),
    regex='test_129[.]ads:13:49: error: '
    'designated type of actual does not match that of formal "T2"',
    sources=(
        ("pak1.ads",
         """-- legal instantiation rejected; illegal instantiation accepted
-- adapted from John Woodruff c.l.a. post

generic
   type T1 is private;
package pak1 is
   subtype T3 is T1;
end pak1;
"""),
        ("pak2.ads", """with pak1;
generic
   type T2 is private;
package pak2 is
   package the_pak1 is new pak1 (T1 => T2);
end pak2;
"""),
        ("pak2-pak3.ads", """generic
   type T2 is access the_pak1.T3;
package pak2.pak3 is
end pak2.pak3;
"""),
        ("test_129.ads", """with pak1;
with pak2.pak3;
package Test_129 is

   type T4 is null record;
   type T5 is null record;
   subtype T3 is T5; -- line 9: triggers the bug at line 16

   type T4_ptr is access T4;
   type T5_ptr is access T5;

   package new_pak2 is new pak2 (T2 => T4);
   package new_pak3a is new new_pak2.pak3(T2 => T4_ptr);  -- line 15: Legal
   package new_pak3b is new new_pak2.pak3(T2 => T5_ptr);  -- line 16: Illegal
end Test_129;
""")))

print("# Please ignore the gnatlink message.")
check_reports_an_error_but_should_not(
    bug=280939,
    make=(f"gnatmake-{new_version}", "test_130"),
    regex="test_130[.]adb:.*: undefined reference to [`]p2\'",
    sources=(
        ("pak1.ads",
         """--  RM 10.1.5(4) "the pragma shall have an argument that is a name
--  denoting that declaration."
--  RM 8.1(16) "The children of a parent library unit are inside the
--  parent's declarative region."

package pak1 is
   pragma Pure;
end pak1;
"""),
        ("pak1-p2.ads", """procedure pak1.p2;
pragma Pure (p2);          -- ERROR: need expanded name
pragma Import (ada, p2);   -- ERROR: need expanded name
pragma Inline (p2);        -- ERROR: need expanded name
"""),
        ("test_130.adb", """with Pak1.P2;
procedure Test_130 is
begin
   Pak1.P2;
end Test_130;
""")))

check_compiles_but_should_not(
    bug=283833,
    make=(f"gnatmake-{new_version}", "test_132"),
    sources=(
        ("pak1.ads",
         """-- RM 8.5.4(5)  the convention of the renamed subprogram shall not
-- be Intrinsic, if the renaming-as-body completes that declaration
-- after the subprogram it declares is frozen.

-- RM 13.14(3)  the end of the declaration of a library package
-- causes freezing of each entity declared within it.

-- RM 6.3.1(7)  the default calling convention is Intrinsic for
-- any other implicitly declared subprogram unless it is a
-- dispatching operation of a tagged type.

package pak1 is
   type T1 is null record;
   procedure p1 (x1: T1);
   type T2 is new T1;
end pak1;
"""),
        ("pak1.adb", """package body Pak1 is
   procedure P1 (X1 : T1) is begin null; end P1;
end Pak1;
"""),
        ("test_132.ads", """with pak1;
package Test_132 is
   procedure p2 (x2: pak1.T2);
end Test_132;
"""),
        ("test_132.adb", """package body Test_132 is
   procedure p2 (x2: pak1.T2) renames pak1.p1; --ERROR: can't rename intrinsic
end Test_132;
""")))

check_compiles_but_should_not(
    bug=283835,
    make=(f"gnatmake-{new_version}", "test_133"),
    sources=(
        ("test_133.ads", """package Test_133 is
   package pak1 is
      type T1 is null record;
   end pak1;

   package pak2 is
      subtype boolean is standard.boolean;
      function "=" (x, y: pak1.T1) return boolean;
   end pak2;

   use pak1, pak2;

   x1: pak1.T1;
   b1: boolean := x1 /= x1;  -- ERROR: ambigous  (gnat misses)
   --  b2: boolean := x1 = x1;   -- ERROR: ambigous
end Test_133;
"""),
        ("test_133.adb", """package body test_133 is
   package body pak2 is
      function "=" (x, y: pak1.T1) return boolean is
      begin
         return true;
      end "=";
   end pak2;
end test_133;
""")))

check_compiles_but_should_not(
    bug=416979,
    make=(f"gnatmake-{new_version}", "pak1"),
    sources=(
        ("pak1.ads", """package pak1 is
   -- RM 7.3(13), 4.9.1(1)
   -- check that discriminants statically match
   type T1(x1: integer) is tagged null record;
   x2: integer := 2;
   x3: constant integer := x2;
   type T2 is new T1 (x2) with private;
   type T3 is new T1 (x3) with private;
private
   type T2 is new T1 (x2) with null record;  --ERROR: nonstatic discriminant
   type T3 is new T1 (x3) with null record;  --ERROR: nonstatic discriminant
end pak1;
"""),))

check_reports_an_error_but_should_not(
    bug=660698,
    make=(f"gnatmake-{new_version}", "proc.adb"),
    regex='proc[.]adb:17:28: error: '
    'there is no applicable operator "And" for type "Standard[.]Integer"',
    sources=(
        ("proc.adb", """procedure Proc is
   package P1 is
      type T is new Integer;
      function "and" (L, R : in Integer) return T;
   end P1;
   package body P1 is
      function "and" (L, R : in Integer) return T is
         pragma Unreferenced (L, R);
      begin
         return 0;
      end "and";
   end P1;
   use type P1.T;
   package P2 is
      use P1;
   end P2;
   G : P1.T := Integer'(1) and Integer'(2);
begin
   null;
end Proc;
"""), ))

check_produces_a_faulty_executable(
    bug=864969,
    make=(f"gnatmake-{new_version}", "main"),
    trigger="main",
    regex="ZZund",
    sources=(
        ("main.adb", """with Ada.Locales, Ada.Text_IO;
procedure Main is
begin
   Ada.Text_IO.Put_Line (String (Ada.Locales.Country)
                       & String (Ada.Locales.Language));
end Main;
"""),))

check_produces_a_faulty_executable(
    bug=894225,
    make=(f"gnatmake-{new_version}", "main"),
    trigger="main",
    sources=(
        ("main.adb",
         """with Ada.Directories, Ada.Text_IO;
procedure Main is
begin
   Ada.Text_IO.Put_Line (Ada.Directories.Containing_Directory ("/a/b/"));
   Ada.Text_IO.Put_Line (Ada.Directories.Containing_Directory ("a/b/"));
   Ada.Text_IO.Put_Line (Ada.Directories.Containing_Directory ("b/"));
end Main;
"""),
    ),
    regex="""^/a/b
a/b
b$""")

try:
    os.rmdir(workspace)
except OSError:
    print(f"Some unconfirmed, not removing directory {workspace}.")
