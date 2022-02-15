OPENFAST=openfast

TURBSIM=turbsim

SIM_FILES_coh:= \
	coh_URef-4_maininput.fst \
	coh_URef-5_maininput.fst \
	coh_URef-6_maininput.fst \
	coh_URef-7_maininput.fst \
	coh_URef-8_maininput.fst \
	coh_URef-9_maininput.fst \
	coh_URef-10_maininput.fst \
	coh_URef-11_maininput.fst \
	coh_URef-12_maininput.fst \
	coh_URef-13_maininput.fst \
	coh_URef-14_maininput.fst \
	coh_URef-15_maininput.fst \
	coh_URef-16_maininput.fst \
	coh_URef-17_maininput.fst \
	coh_URef-18_maininput.fst \
	coh_URef-19_maininput.fst \
	coh_URef-20_maininput.fst \
	coh_URef-21_maininput.fst \
	coh_URef-22_maininput.fst 

OUT_FILES_coh:= $(patsubst %.fst, %.outb, $(SIM_FILES_coh))


all: $(OUT_FILES_coh)

coh: $(OUT_FILES_coh)


coh_URef-4_maininput.outb: ../wind/COH_URef-4_turbsim.bts

coh_URef-5_maininput.outb: ../wind/COH_URef-5_turbsim.bts

coh_URef-6_maininput.outb: ../wind/COH_URef-6_turbsim.bts

coh_URef-7_maininput.outb: ../wind/COH_URef-7_turbsim.bts

coh_URef-8_maininput.outb: ../wind/COH_URef-8_turbsim.bts

coh_URef-9_maininput.outb: ../wind/COH_URef-9_turbsim.bts

coh_URef-10_maininput.outb: ../wind/COH_URef-10_turbsim.bts

coh_URef-11_maininput.outb: ../wind/COH_URef-11_turbsim.bts

coh_URef-12_maininput.outb: ../wind/COH_URef-12_turbsim.bts

coh_URef-13_maininput.outb: ../wind/COH_URef-13_turbsim.bts

coh_URef-14_maininput.outb: ../wind/COH_URef-14_turbsim.bts

coh_URef-15_maininput.outb: ../wind/COH_URef-15_turbsim.bts

coh_URef-16_maininput.outb: ../wind/COH_URef-16_turbsim.bts

coh_URef-17_maininput.outb: ../wind/COH_URef-17_turbsim.bts

coh_URef-18_maininput.outb: ../wind/COH_URef-18_turbsim.bts

coh_URef-19_maininput.outb: ../wind/COH_URef-19_turbsim.bts

coh_URef-20_maininput.outb: ../wind/COH_URef-20_turbsim.bts

coh_URef-21_maininput.outb: ../wind/COH_URef-21_turbsim.bts

coh_URef-22_maininput.outb: ../wind/COH_URef-22_turbsim.bts


%.outb : %.fst
	$(OPENFAST) $< > $*.log

%.bts : %.inp
	$(TURBSIM) $< > $*.log

.PHONY: clean all
