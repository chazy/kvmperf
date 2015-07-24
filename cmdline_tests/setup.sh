uname -a | grep -q x86_64
if [[ $? == 0 ]]; then
	TOOLS=tools_x86
	x86=1
	arm64=0
else
	TOOLS=tools_arm64
	x86=0
	arm64=1
fi
