from locust import HttpUser, between, task


class SmokeUser(HttpUser):
    """疎通確認用: GET / を1本だけ投げる。"""

    wait_time = between(1, 3)

    @task
    def index(self):
        self.client.get("/")
