(cd instances; terraform apply -auto-approve)
echo "running"
instance_ip="$(cd instances; terraform output -raw us-west-1_public_ip)"
down=210
up=30
prefix=terrestrial

./run_world_iperf3.sh -n -d ${down}M -u ${up}M ../packet_full_2022-07-23_${prefix}_iperf3
./run_world_iperf3.sh -n -d $(((${down}+1)/2))M -u $(((${up}+1)/2))M../packet_half_2022-07-23_${prefix}_iperf3
./run_world_iperf3.sh -n -d $(((${down}+2)/3))M -u $(((${up}+2)/3))M../packet_third_2022-07-23_${prefix}_iperf3
./run_world_iperf3.sh -n -d $(((${down}+3)/4))M -u $(((${up}+3)/4))M../packet_quarter_2022-07-23_${prefix}_iperf3
./run_world_iperf3.sh -n -d $(((${down}+4)/5))M -u $(((${up}+4)/5))M../packet_fifth_2022-07-23_${prefix}_iperf3

(cd instances; terraform destroy -auto-approve)
