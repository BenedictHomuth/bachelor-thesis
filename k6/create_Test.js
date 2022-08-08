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
    const linkCreate = `${HOSTNAME}/create`
    const payload = JSON.stringify({
        title: 'A todo',
        description: 'Stuff to do!',
      })
    const params = {
         headers: {
          'Content-Type': 'application/json',
         },
    }
    http.post(linkCreate, payload, params)
    sleep(1)
}