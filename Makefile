FC = gfortran
FFLAGS = -O2 -Wall
TARGET = test_cii_writers
SRCS = format_utils.f90 cii_model_types.f90 write_version_control.f90 write_elements.f90 write_bend_rigid_restrant.f90 write_sif_allowbls_units.f90 generated_driver.f90

all: $(TARGET)

$(TARGET): $(SRCS)
	$(FC) $(FFLAGS) -o $@ $^

clean:
	rm -f *.o *.mod $(TARGET) BM_CII_out.CII generated_driver.f90
