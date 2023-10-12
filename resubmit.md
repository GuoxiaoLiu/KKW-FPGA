We express our sincere gratitude to the reviewers for providing us with valuable feedback that has significantly enhanced the quality of this article. We had received 6 requirements from the reviewers during the previous submission, and in this section, we will elaborate on how we addressed these six requirements through the revision of the paper.

R1: Add tests (test vectors, simulation of the VHDL code, and/or tests with an FPGA board) to support the statements about the correctness of the implementations. 

- In response to this requirement, we have added a test vector on https://anonymous.4open.science/r/CHES2024-64F9. Additionally, we have included a test vector that can be utilized for simulating the VHDL code using vivado, allowing for the verification of the code's correctness.

R2: Give more details about the hardware architecture. 

- To provide a better understanding of the hardware architecture, we have reintroduced the hardware architecture overview in Figure 7 of Section 4 in the paper. Furthermore, for improved clarity, we have renamed the optimized Step 1 and Step 3 in Section 4.3 (l.502) as Step 1' and Step 3' respectively. We have also explained the reasons behind the decision of not pipelining Step 1', Step 2, and Step 3' (l.568). After testing the clock cycle of Table 8, we have made adjustments since Step 1' takes longer than Step 2. As Step 1' does not require much hardware for optimization, we have provided the second version of L5.

R3: Add area-time products for comparisons. 

- We have included the area-time product in Table 10. Since the previous test did not measure Slice, we have estimated the number of Slices by LUT/4 based on [NKeSK+22] and calculated the area-time product accordingly. Our AT performance remains the best at the L1 security level. Moreover, at the L5 level, our AT performance also outperforms other digital signature schemes based on symmetric primitives.

R4: Explain which of the ideas generalize to other MPCitH schemes and which are tailored to LowMC. 

- In Section 6, we have provided an explanation regarding the technologies that can be applied to the MPCitH solution, as well as those that are specific to LowMC. Our technique in Section 3 is solely applicable to block ciphers that are inversible for all linear operations based on the KKW protocol, not just LowMC. On the other hand, the ideas presented in Sections 4 and 5 can be implemented in most MPCitH protocols.

R5: Explain the challenges in adapting the design of [KRR+20] to Picnic3 in more depth. 

- In Section 3 (l.377), we have elaborated on the reasons why the method employed in [KRR+20] cannot be directly applied to Picnic3. This is primarily due to the disparity in hardware usage between the LowMC-MPC of [KRR+20] (O((N-1)(C_L+C_N))) and our implementation (O(2N C_L + C_N)). As the linear operands of LowMC are significantly larger than the nonlinear operands, we are able to accommodate more participants. Table 3 demonstrates that the 3-party LowMC-MPC used in [KRR+20] requires more hardware compared to our 8-party LowMC-MPC.

R6: Make the comparison more fair by using the same devices, including A7 and smaller K7. 

- In order to ensure fairness in the experimental results, we have conducted tests utilizing A7 and K7, adding them to Table 7 and Table 10.