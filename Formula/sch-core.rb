class SchCore < Formula
  desc "Implementation and computation algorithms for the convex hulls"
  homepage "https://github.com/jrl-umi3218/sch-core"
  url "https://github.com/jrl-umi3218/sch-core/releases/download/v1.4.2/sch-core-v1.4.2.tar.gz"
  sha256 "6e8e23108987fb3ebc5cc6a651ff17cfb77fc8373cc69be8ad3999c6f3ac82cf"
  license "BSD-2-Clause"
  revision 0

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/sch-core-1.4.0"
    sha256 cellar: :any,                 monterey:     "3a277734db2fbc3449d81982f4aa92156bd6a52478c56aef503f5034c1932d0f"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "ff0c54541ea7fa307b7da7d83199c07705d7a77b7aa95b6874ae54400bf61d87"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "boost"

  resource "common.cpp" do
    url "https://raw.githubusercontent.com/jrl-umi3218/sch-shared-tests/1841233dd3aaeb4a37a8b28537a73f001674c615/tests/common.cpp"
    sha256 "1101d274380ce60a8c91a80dd21429f70f80243a202148d76eea8f3b43f79bdd"
  end

  resource "common.h" do
    url "https://raw.githubusercontent.com/jrl-umi3218/sch-shared-tests/1841233dd3aaeb4a37a8b28537a73f001674c615/tests/common.h"
    sha256 "7d480549dc51c1087e005e3531149202dbec318886ac083833ce496be543ea9c"
  end

  resource "includes.h" do
    url "https://raw.githubusercontent.com/jrl-umi3218/sch-shared-tests/1841233dd3aaeb4a37a8b28537a73f001674c615/tests/includes.h"
    sha256 "236cb80343bd1fc7a6f09971293f16b3dcd245ce728ee0555e2b37f928043c3a"
  end

  resource "sample_stpbv1.txt" do
    url "https://raw.githubusercontent.com/jrl-umi3218/sch-shared-tests/1841233dd3aaeb4a37a8b28537a73f001674c615/data/sample_stpbv1.txt"
    sha256 "cd2344237e6184cf4ebe5e23d1784db4749012b9b8ddae175c207222bf8e37b5"
  end

  resource "sample_stpbv2.txt" do
    url "https://raw.githubusercontent.com/jrl-umi3218/sch-shared-tests/1841233dd3aaeb4a37a8b28537a73f001674c615/data/sample_stpbv2.txt"
    sha256 "a052925e67d7181375464c451fc6fdab68e368d27a6793a0dbf1671307fd04e1"
  end

  def install
    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

    args = std_cmake_args + %w[
      -DCMAKE_CXX_STANDARD=11
      -DINSTALL_DOCUMENTATION:BOOL=OFF
      -DSCH_BUILD_BSD:BOOL=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    resource("common.cpp").stage testpath
    resource("common.h").stage testpath
    resource("includes.h").stage testpath
    resource("sample_stpbv1.txt").stage testpath
    resource("sample_stpbv2.txt").stage testpath

    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.1)
      set(CMAKE_CXX_STANDARD 11)
      project(Brewsch-core LANGUAGES CXX)
      find_package(sch-core REQUIRED)
      add_executable(main main.cpp common.cpp)
      target_link_libraries(main PUBLIC sch-core::sch-core)
    EOS
    (testpath/"main.cpp").write <<~EOS
      #define NON_STP_BV_OBJECTS true

      #include "common.h"

      using namespace sch;

      void display() {}

      int main() {
        TestMaterial universe = TestMaterial(NON_STP_BV_OBJECTS);
        universe.initializeUniverse();
        universe.GeneralTest();
        return 0;
      }
    EOS
    # Avoid introducing march=native which will cause ABI breaks
    ENV["CXXFLAGS"] = ""
    system "cmake", ".", *std_cmake_args
    system "cmake", "--build", "."
    system "./main"
  end
end
