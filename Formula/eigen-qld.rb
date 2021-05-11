class EigenQld < Formula
  desc "Allows to use the QLD QP solver with the Eigen3 library"
  homepage "https://github.com/jrl-umi3218/eigen-qld"
  url "https://github.com/jrl-umi3218/eigen-qld/releases/download/v1.2.1/eigen-qld-v1.2.1.tar.gz"
  sha256 "680e74f02245885cfa639993dd7224c4f5641f4d40ceb619dce710f93d6791c2"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/eigen-qld-1.2.1"
    sha256 cellar: :any,                 catalina:     "d955fb7151d3a2647b5269915e0ec8ce6f781914926c52a559ac8267e1fa2888"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "8243e31ad6f7132da0fe60a9f2764d1b53b6525ae40eb5c4e311256965c0a9c4"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "cython" => :build
  depends_on "eigen"
  depends_on "eigen3topython"

  def install
    xy = Language::Python.major_minor_version Formula["python"].opt_bin/"python3"
    ENV.prepend_create_path "PYTHONPATH", Formula["cython"].opt_libexec/"lib/python#{xy}/site-packages"

    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

    inreplace "cmake/cython/cython.cmake",
              "set(PIP_EXTRA_OPTIONS --target \"${PIP_TARGET}\")",
              "set(PIP_EXTRA_OPTIONS --prefix \"${PIP_INSTALL_PREFIX}\")"

    args = std_cmake_args + %W[
      -DINSTALL_DOCUMENTATION:BOOL=OFF
      -DPIP_INSTALL_PREFIX=#{prefix}
      -DPYTHON_BINDING_FORCE_PYTHON3:BOOL=ON
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

    system Formula["python"].opt_bin/"python3", "-c", <<~EOS
      import eigen_qld
    EOS
  end
end
