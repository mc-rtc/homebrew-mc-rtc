class StateObservation < Formula
  desc "Describes interfaces for state observers, and implements some observers"
  homepage "https://github.com/jrl-umi3218/state-observation/"
  url "https://github.com/jrl-umi3218/state-observation/releases/download/v1.5.3/state-observation-v1.5.3.tar.gz"
  sha256 "8f4814649d7dc9444b5dc7e1ee156320315a340d1cf942bea715b09df6675014"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/state-observation-1.5.3"
    sha256 cellar: :any,                 monterey:     "5c53949dbb2daaead4c5f1cc53262fe2c4390b677e800d18cc67c671c3048c00"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "9a9dca4e551339e5112d1b2f4d63f9047cc850941d046d6539f37285960cb33a"
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
