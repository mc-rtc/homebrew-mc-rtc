class StateObservation < Formula
  desc "Describes interfaces for state observers, and implements some observers"
  homepage "https://github.com/jrl-umi3218/state-observation/"
  url "https://github.com/jrl-umi3218/state-observation/releases/download/v1.5.0/state-observation-v1.5.0.tar.gz"
  sha256 "509529785a14459b48edd4943840add9315f1d947db1db6f79f7f7ef1ac02d99"
  license "BSD-2-Clause"
  revision 0

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/state-observation-1.4.1_2"
    sha256 cellar: :any,                 big_sur:      "35b60dd0f6dddf71036bd75abaf152617ab477be7fcee5e5ad1288af83ca1d13"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "20c9f3a03aaf85de577fe236aee5a25cc59f3a681a263cf78824397d837ed431"
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
