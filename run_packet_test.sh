(cd instances; terraform apply -auto-approve)
echo "running"
instance_ip="$(cd instances; terraform output -raw us-west-1_public_ip)"
down=210
prefix=terrestrial

./run_world_iperf3.sh -n -d ${down}M -u ../packet_full_2022-07-23_${prefix}_iperf3
./run_world_iperf3.sh -n -d $(((${down}+1)/2))M -u ../packet_half_2022-07-23_${prefix}_iperf3
./run_world_iperf3.sh -n -d $(((${down}+2)/3))M -u ../packet_third_2022-07-23_${prefix}_iperf3
./run_world_iperf3.sh -n -d $(((${down}+3)/4))M -u ../packet_quarter_2022-07-23_${prefix}_iperf3
./run_world_iperf3.sh -n -d $(((${down}+4)/5))M -u ../packet_fifth_2022-07-23_${prefix}_iperf3

(cd instances; terraform destroy -auto-approve)
