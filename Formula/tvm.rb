class Tvm < Formula
  desc "Writing and solving linear control problems for robot"
  homepage "https://github.com/jrl-umi3218/tvm/"
  url "https://github.com/jrl-umi3218/tvm/releases/download/v0.9.2/tvm-v0.9.2.tar.gz"
  sha256 "9b25ad4d068ba980e25ae0f600830bcb7cab4cd5fbb7aca337dacaf0678f3a69"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/tvm-0.9.2"
    sha256 cellar: :any,                 monterey:     "4f22a73d78b3dc369665dfc58abdf13ce92a83dc2ad6775be5952c0c7688975f"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "a8c85fe470e4ff61d6537584d1d15d379fec130246b153b1643e01491d3e61d4"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "boost"
  depends_on "eigen-qld"
  depends_on "eigen-quadprog"

  def install
    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

    args = std_cmake_args + %w[
      -DINSTALL_DOCUMENTATION:BOOL=OFF
      -DTVM_WITH_QLD:BOOL=ON
      -DTVM_WITH_QUADPROG:BOOL=ON
      -DTVM_WITH_ROBOT:BOOL=OFF
      -DTVM_THOROUGH_TESTING:BOOL=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.1)
      set(CMAKE_CXX_STANDARD 11)
      project(BrewTVM LANGUAGES CXX)
      find_package(TVM REQUIRED)
      add_executable(main test_tvm.cpp)
      target_link_libraries(main PUBLIC TVM::TVM)
    EOS
    (testpath/"test_tvm.cpp").write <<~EOS
      #include <tvm/Range.h>
      #include <tvm/Variable.h>

      using namespace tvm;

      #define FAST_CHECK_EQ(a, b)                 \
        if(a != b)                                \
        {                                         \
          throw std::runtime_error("Unexpected"); \
        }

      int main()
      {
        Space R2(2);
        Space R3(3);
        Space SO3(Space::Type::SO3);
        Space S2(2, 3, 3);

        Space R5 = R2 * R3;
        FAST_CHECK_EQ(R5.size(), 5);
        FAST_CHECK_EQ(R5.rSize(), 5);
        FAST_CHECK_EQ(R5.tSize(), 5);
        FAST_CHECK_EQ(R5.type(), Space::Type::Euclidean);

        Space SE3 = R3 * SO3;
        FAST_CHECK_EQ(SE3.size(), 6);
        FAST_CHECK_EQ(SE3.rSize(), 7);
        FAST_CHECK_EQ(SE3.tSize(), 6);
        FAST_CHECK_EQ(SE3.type(), Space::Type::Unspecified);

        Space S = R2 * S2;
        FAST_CHECK_EQ(S.size(), 4);
        FAST_CHECK_EQ(S.rSize(), 5);
        FAST_CHECK_EQ(S.tSize(), 5);
        FAST_CHECK_EQ(S.type(), Space::Type::Unspecified);
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
