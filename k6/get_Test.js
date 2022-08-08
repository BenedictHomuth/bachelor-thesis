import http from 'k6/http'
import { sleep } from 'k6'

export const options = {
    stages: [
        {duration: "10s", target: 100},
        {duration: "10s", target: 150},
    ]
}

export default function(){
    const HOSTNAME = "http://k3s-load-balancer-950254481.eu-central-1.elb.amazonaws.com/todos"
    const linkGetAll = `${HOSTNAME}/get`
    
    //  Execution 
      http.get(linkGetAll)
      sleep(1)
}