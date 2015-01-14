% IP address
function address = ip(local)

if nargin == 0
   local = true;
end

if local
   address = java.net.InetAddress.getLocalHost;
   address = char(address.getHostAddress);
else
   address = urlread('http://icanhazip.com/');
end