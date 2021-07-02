#!/bin/bash
yum install amazon-cloudwatch-agent -y
cd /opt/aws/amazon-cloudwatch-agent/bin
cat > /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent.json << 'EOF'
{
 "agent":{
	 
 "metrics_collection_interval":60
	},
	"metrics":{
	   "namespace":"ASG_Memory",
	   "append_dimensions":{
		  "AutoScalingGroupName":"$${aws:AutoScalingGroupName}",
		  "InstanceId":"$${aws:InstanceId}"
	   },
	   "aggregation_dimensions":[
		  [
			 "AutoScalingGroupName"
		  ]
	   ],
	   "metrics_collected":{
		  "mem":{
			 "measurement":[
				{
				   "name":"mem_used_percent",
				   "rename":"MemoryUtilization",
				   "unit":"Percent"
				}
			 ],
			 "metrics_collection_interval":60
		  }
	   }
	}
}
EOF
./amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:amazon-cloudwatch-agent.json
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent