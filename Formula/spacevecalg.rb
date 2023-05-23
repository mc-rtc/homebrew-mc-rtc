class Spacevecalg < Formula
  desc "Implementation of spatial vector algebra with the Eigen3 linear algebra library"
  homepage "https://github.com/jrl-umi3218/SpaceVecAlg"
  url "https://github.com/jrl-umi3218/SpaceVecAlg/releases/download/v1.2.4/SpaceVecAlg-v1.2.4.tar.gz"
  sha256 "8433ba5ebc5001e312cb59080c609de6e5e3439cbfbc5f433463b2c4a23ede36"
  license "BSD-2-Clause"
  revision 0

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/spacevecalg-1.2.4"
    sha256 cellar: :any_skip_relocation, monterey:     "9c02769c93aa2908b6e88d473289af41954faefd628cc2cfa23cf214d5a1120a"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "d312e2ddc4ef9bcf8453c4e2415d220ae8ddb13d087bf8c8c4909fb9dc4ee0e7"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "eigen"

  def install
    args = std_cmake_args + %w[
      -DINSTALL_DOCUMENTATION:BOOL=OFF
      -DPYTHON_BINDING:BOOL=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.1)
      project(BrewSpaceVecAlg LANGUAGES CXX)
      find_package(SpaceVecAlg REQUIRED)
      add_executable(main main.cpp)
      target_link_libraries(main PUBLIC SpaceVecAlg::SpaceVecAlg)
    EOS
    (testpath/"main.cpp").write <<~EOS
      #include <SpaceVecAlg/SpaceVecAlg>
      #include <iostream>

      int main() {
        auto pt = sva::PTransformd::Identity();
        std::cout << pt.rotation() << "\\n" << pt.translation().transpose() << "\\n";
        return 0;
      }
    EOS
    system "cmake", ".", *std_cmake_args
    system "make"
    system "./main"
  end
end
