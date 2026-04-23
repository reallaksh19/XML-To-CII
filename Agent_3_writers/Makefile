FC = gfortran
FFLAGS = -O2 -Wall

OBJS = cii_model_types.o write_coords.o write_hanger_miscel.o write_nodename.o
TARGET = test_harness test_nodename test_miscel_coords

all: $(TARGET)

test_harness: $(OBJS) main.o
	$(FC) $(FFLAGS) -o $@ $^

test_nodename: cii_model_types.o write_nodename.o main_nodename.o
	$(FC) $(FFLAGS) -o $@ $^

test_miscel_coords: cii_model_types.o write_hanger_miscel.o write_coords.o main_miscel_coords.o
	$(FC) $(FFLAGS) -o $@ $^

%.o: %.f90
	$(FC) $(FFLAGS) -c $<

write_nodename.o: cii_model_types.o
write_hanger_miscel.o: cii_model_types.o
main.o: cii_model_types.o write_nodename.o write_hanger_miscel.o write_coords.o
main_nodename.o: cii_model_types.o write_nodename.o
main_miscel_coords.o: cii_model_types.o write_hanger_miscel.o write_coords.o

clean:
	rm -f *.o *.mod $(TARGET) test_output*.CII
