# TF-302 Section 2: Check blocks — tests
#
# libvirt and http are mocked, so these run without a daemon or a web server.
#
# Two things about checks in `terraform test`:
# - A failing check fails the run, unless the run lists it in expect_failures.
# - A check that is still "known after apply" at the end of a plan run also
#   fails it. web_health reads from the VM, so it's deferred during plan:
#   these runs use command = apply, which is safe with mocked providers.

mock_provider "libvirt" {
  mock_data "libvirt_node_info" {
    defaults = {
      memory_total_kb = 16777216 # a 16 GiB host
    }
  }
}

mock_provider "http" {}

run "all_checks_pass" {
  command = apply

  override_data {
    target = data.http.home # a data source inside a check keeps its normal address
    values = {
      status_code   = 200
      response_body = "hello from tf302-web"
    }
  }

  assert {
    condition     = output.url == "http://10.160.0.10/"
    error_message = "The URL should use the reserved address"
  }
}

run "web_server_unhealthy" {
  command = apply

  override_data {
    target = data.http.home
    values = {
      status_code   = 502
      response_body = "Bad Gateway"
    }
  }

  expect_failures = [check.web_health]
}

run "wrong_server_answers" {
  command = apply

  override_data {
    target = data.http.home
    values = {
      status_code   = 200
      response_body = "Welcome to nginx!"
    }
  }

  expect_failures = [check.web_health]
}

run "host_headroom_warning" {
  command = apply

  variables {
    memory_mb = 14336 # leaves 2 GiB on a 16 GiB host
  }

  override_data {
    target = data.http.home
    values = {
      status_code   = 200
      response_body = "hello from tf302-web"
    }
  }

  expect_failures = [check.host_memory_headroom]
}
