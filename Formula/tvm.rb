class Tvm < Formula
  desc "Writing and solving linear control problems for robot"
  homepage "https://github.com/jrl-umi3218/tvm/"
  url "https://github.com/jrl-umi3218/tvm/releases/download/v0.9.0/tvm-v0.9.0.tar.gz"
  sha256 "761265694287c36bff1c406ee0b6f2936234a4e1e69736caa6a4976d2813d050"
  license "BSD-2-Clause"
  revision 1

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/tvm-0.9.0"
    sha256 cellar: :any,                 monterey:     "8912a594c0af211cba8c3f21d231b4b557d69e70a11eb7d1f9cfa7e7855de558"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "34cb30d721c188c8ee7330595608b1529fe0a71a313643fef87a704045d393df"
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
