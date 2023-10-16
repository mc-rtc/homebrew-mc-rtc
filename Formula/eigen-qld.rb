class EigenQld < Formula
  desc "Allows to use the QLD QP solver with the Eigen3 library"
  homepage "https://github.com/jrl-umi3218/eigen-qld"
  url "https://github.com/jrl-umi3218/eigen-qld/releases/download/v1.2.4/eigen-qld-v1.2.4.tar.gz"
  sha256 "631a69015f2c9e36243e390254adfc57293599a1fd18d35a22e5a6b6f8c5a4f0"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/eigen-qld-1.2.4"
    rebuild 1
    sha256 cellar: :any,                 monterey:     "e71f860e6f92b13001525d9cfa28955c5e1174024fd0d3d07480e2ede3acebe8"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "a9ee65573a385ccab7849d66863cee5a2ba4de38f88167247de7cd55896f2632"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "eigen"
  depends_on "gcc" # for gfortran

  def install
    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

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
      project(BrewEigenQldld LANGUAGES CXX)
      find_package(eigen-qld REQUIRED)
      add_executable(main main.cpp)
      target_link_libraries(main PUBLIC eigen-qld::eigen-qld)
    EOS
    (testpath/"main.cpp").write <<~EOS
      #include <eigen-qld/QLD.h>

      #include <iostream>

      struct QP1
      {
        QP1()
        {
          nrvar = 6;
          nreq = 3;
          nrineq = 2;

          Q.resize(nrvar, nrvar);
          Aeq.resize(nreq, nrvar);
          Aineq.resize(nrineq, nrvar);
          A.resize(nreq + nrineq, nrvar);

          C.resize(nrvar);
          Beq.resize(nreq);
          Bineq.resize(nrineq);
          B.resize(nreq + nrineq);
          XL.resize(nrvar);
          XU.resize(nrvar);
          X.resize(nrvar);

          Aeq << 1., -1., 1., 0., 3., 1., -1., 0., -3., -4., 5., 6., 2., 5., 3., 0., 1., 0.;
          Beq << 1., 2., 3.;

          Aineq << 0., 1., 0., 1., 2., -1., -1., 0., 2., 1., 1., 0.;
          Bineq << -1., 2.5;

          A.topRows(nreq) = Aeq;
          A.bottomRows(nrineq) = -Aineq;

          B.head(nreq) = -Beq;
          B.tail(nrineq) = Bineq;

          // with  x between ci and cs:
          XL << -1000., -10000., 0., -1000., -1000., -1000.;
          XU << 10000., 100., 1.5, 100., 100., 1000.;

          // and minimize 0.5*x'*Q*x + p'*x with
          C << 1., 2., 3., 4., 5., 6.;
          Q.setIdentity();

          X << 1.7975426, -0.3381487, 0.1633880, -4.9884023, 0.6054943, -3.1155623;
        }

        int nrvar, nreq, nrineq;
        Eigen::MatrixXd Q, Aeq, Aineq, A;
        Eigen::VectorXd C, Beq, Bineq, B, XL, XU, X;
      };

      int main()
      {
        QP1 qp1;
        std::cout << "qp1.X: " << qp1.X.transpose() << "\\n";

        Eigen::QLD qld(qp1.nrvar, qp1.nreq, qp1.nrineq);
        qld.solve(qp1.Q, qp1.C, qp1.Aeq, qp1.Beq, qp1.Aineq, qp1.Bineq, qp1.XL, qp1.XU);
        std::cout << "qld.result(): " << qld.result().transpose() << "\\n";

        Eigen::QLDDirect qldd(qp1.nrvar, qp1.nreq, qp1.nrineq);
        qldd.solve(qp1.Q, qp1.C, qp1.A, qp1.B, qp1.XL, qp1.XU, 3);
        std::cout << "qldd.result(): " << qldd.result().transpose() << "\\n";

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
