class StateObservation < Formula
  desc "Describes interfaces for state observers, and implements some observers"
  homepage "https://github.com/jrl-umi3218/state-observation/"
  url "https://github.com/jrl-umi3218/state-observation/releases/download/v1.5.1/state-observation-v1.5.1.tar.gz"
  sha256 "7637e148e5141b943552756d1b2f2b337c5fe96d2c51257a6219be8e491c0621"
  license "BSD-2-Clause"
  revision 0

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/state-observation-1.5.1"
    sha256 cellar: :any,                 monterey:     "098f6ee15383c1647b3507a75c7e7a1c0609851f710cc9380a3bd0e396af447b"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "01128a2b2e1a4ae5aa2b760bf34f82cf35e2920dde7a7e1762270f42f77dfd9a"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "boost"
  depends_on "eigen"

  resource "test.cpp" do
    url "https://raw.githubusercontent.com/jrl-umi3218/state-observation/v1.4.1/unit-testings/test_acceleration_stabilization.cpp"
    sha256 "f10d373523eed1ea3908ab36383286bbc1ec9d77e867173e4b38c0181b16701d"
  end

  def install
    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

    args = std_cmake_args + %w[
      -DINSTALL_DOCUMENTATION:BOOL=OFF
      -DBUILD_STATE_OBSERVATION_TOOLS:BOOL=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    resource("test.cpp").stage testpath
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.1)
      set(CMAKE_CXX_STANDARD 11)
      project(Brewstate-observation LANGUAGES CXX)
      find_package(state-observation REQUIRED)
      add_executable(main test_acceleration_stabilization.cpp)
      target_link_libraries(main PUBLIC state-observation::state-observation)
    EOS
    # Avoid introducing march=native which will cause ABI breaks
    ENV["CXXFLAGS"] = ""
    system "cmake", ".", *std_cmake_args
    system "cmake", "--build", "."
    system "./main"
  end
end
