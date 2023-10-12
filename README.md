The different folders and files are:

- `High_Performance_Implementation_of_MPCitH_and_Picnic3.pdf`: Anonymous papers submitted by us.
- `OverallFinal.pdf`: The architecture diagram of Picnic3 core, but the input and output are simplified.
- `KKW-4-L1-V1`: Picnic3 signing algorithm version 1 with security level L1 implemented in Section 5 of this paper.
- `KKW-4-L1-V2`: Picnic3 signing algorithm version 2 with security level L1 implemented in Section 5 of this paper.
- `KKW-4-L1-V3`: Picnic3 signing algorithm version 3 with security level L1 implemented in Section 5 of this paper.
- `KKW-4-L1-verify`: Picnic3 signing and verification algorithm with security level L1 implemented in Section 5 of this paper.
- `KKW-4-L5`: Picnic3 signing algorithm with security level L5 implemented in Section 5 of this paper.
- `KKW-4-L5-verify`: Picnic3 signing and verification algorithm with security level L1 implemented in Section 5 of this paper.
- `LowMC-MPC-3`: LowMC-MPC of 3 parties implemented in Section 3 (Table 3) of this paper.
- `LowMC-MPC-4`: LowMC-MPC of 4 parties implemented in Section 3 (Table 3) of this paper.
- `LowMC-MPC-8`: LowMC-MPC of 8 parties implemented in Section 3 (Table 3) of this paper.
- `LowMC-MPC-16`: LowMC-MPC of 16 parties implemented in Section 3 (Table 3) of this paper.
- `Keccak`: Keccak of different clock cycles implemented in Section 4.2 (Table 4) of this paper.

Testbench:
- You can use KKW-4-L1-verify and KKW-4-L5-verify to check the signing and verification.

Architecture:
- In the figure, the LowMC-MPC core should execute offline first, and then execute online. The seed includes the construction of Step 1 and the pipeline of Step 2, and $H_{on}$ includes Step 3 and the pipeline of Step 2.
