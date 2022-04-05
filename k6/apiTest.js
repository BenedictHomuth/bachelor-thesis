import http from 'k6/http'
import { sleep } from 'k6'

export const options = {
    stages: [
        {duration: "10s", target: 10},
        {duration: "10s", target: 15},
        {duration: "10s", target: 0},
    ]
}

export default function(){
    const linkGetAll = `${__ENV.HOSTNAME}/get`
    const linkCreate = `${__ENV.HOSTNAME}/create`
    const payload = JSON.stringify({
        title: 'todo',
        description: 'go to work!',
      })
    const params = {
         headers: {
          'Content-Type': 'application/json',
         },
     }
    
    //  Execution 
      http.post(linkCreate, payload, params)
      sleep(1)

      http.get(linkGetAll)
      sleep(1)
}