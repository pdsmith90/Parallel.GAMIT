import functools
from django.test import TestCase
from . import models
from django.urls import reverse
from django.db import connection
import django.apps
import datetime
from unittest import TestCase

# tests.py

from django.db import connection
from django.test import TestCase
from . import views
from . import models
import django.contrib.auth.hashers
from django.test import Client

class PermissionsTest(TestCase):
    def authenticate_admin(self):
        url = reverse("token_obtain_pair")

        response = self.client.post(
            url, {"username": "admin", "password": "admin"})

        self.assertEqual(response.status_code, 200)

        self.token = response.json()["access"]

        self.assertIsNotNone(self.token)
        self.client.defaults['HTTP_AUTHORIZATION'] = "Bearer " + self.token

    def authenticate_underprivileged_front(self):
        url = reverse("token_obtain_pair")

        response = self.client.post(
            url, {"username": "underprivileged_front", "password": "underprivileged_front"})

        self.assertEqual(response.status_code, 200)

        self.token = response.json()["access"]

        self.assertIsNotNone(self.token)
        self.client.defaults['HTTP_AUTHORIZATION'] = "Bearer " + self.token


    def authenticate_underprivileged_api(self):
        url = reverse("token_obtain_pair")

        response = self.client.post(
            url, {"username": "underprivileged_api", "password": "underprivileged_api"})

        self.assertEqual(response.status_code, 200)

        self.token = response.json()["access"]

        self.assertIsNotNone(self.token)
        self.client.defaults['HTTP_AUTHORIZATION'] = "Bearer " + self.token

    def test_admin_role(self):
        self.authenticate_admin()

        url = reverse("station_list")

        response = self.client.get(url)

        self.assertEqual(response.status_code, 200)

        url = reverse("antennas_list")

        response = self.client.get(url)

        self.assertEqual(response.status_code, 200)

        response = self.client.post(url,{
                "antenna_code": "ANT1",
                "antenna_description": "test description"
            })

        self.assertEqual(response.status_code, 201)
    
    def test_disabled_role(self):
        self.authenticate_underprivileged_api()
        
        # test user is enabled

        url = reverse("station_list")

        response = self.client.get(url)

        self.assertEqual(response.status_code, 200)

        # disable role

        self.authenticate_admin()

        url = reverse("role_detail", kwargs={"pk": models.User.objects.get(username="underprivileged_api").role.id})

        response = self.client.patch(url, data = {"is_active": False}, content_type='application/json')

        self.assertEqual(response.status_code, 200)

        self.assertEqual(models.User.objects.get(username="underprivileged_api").role.is_active, False)

        # check user is disabled

        url = reverse("token_obtain_pair")

        response = self.client.post(
            url, {"username": "underprivileged_api", "password": "underprivileged_api"})

        self.assertEqual(response.status_code, 401)

        #check user cannot be enable until role is active

        self.authenticate_admin()

        url = reverse("user_detail", kwargs={"pk": models.User.objects.get(username="underprivileged_api").id})

        response = self.client.patch(url, data = {"is_active": True}, content_type='multipart/form-data')

        self.assertEqual(response.status_code, 400)

        # enable user but not role, check user is unable of accessing the api

        user = models.User.objects.get(username="underprivileged_api")

        user.is_active = True

        user.save()

        self.assertEqual(models.User.objects.get(username="underprivileged_api").is_active, True)

        self.authenticate_underprivileged_api()

        url = reverse("station_list")

        response = self.client.get(url)

        self.assertEqual(response.status_code, 403)

        # enable role

        self.authenticate_admin()

        url = reverse("role_detail", kwargs={"pk": models.User.objects.get(username="underprivileged_api").role.id})

        response = self.client.patch(url, data = {"is_active": True}, content_type='application/json')

        self.assertEqual(response.status_code, 200)

        self.authenticate_underprivileged_api()

        url = reverse("station_list")

        response = self.client.get(url)

        self.assertEqual(response.status_code, 200)

    def test_underprivileged_front_role(self):
        self.authenticate_underprivileged_front()

        url = reverse("station_list")

        response = self.client.get(url)

        self.assertEqual(response.status_code, 200)

        response = self.client.post(url,{
                "station_code": "ST1",
                "station_name": "test station"
            })

        self.assertEqual(response.status_code, 403)

        url = reverse("antennas_list")

        response = self.client.get(url)
        
        self.assertEqual(response.status_code, 403)

    def test_underprivileged_api_role(self):
        self.authenticate_underprivileged_api()

        url = reverse("station_list")

        response = self.client.get(url)

        self.assertEqual(response.status_code, 200)

        response = self.client.post(url,{
                "station_code": "ST1",
                "station_name": "test station"
            })

        self.assertEqual(response.status_code, 403)

        url = reverse("antennas_list")

        response = self.client.get(url)
        
        self.assertEqual(response.status_code, 403)

class StationInfoTest(TestCase):
    """
    Test validation for creating and updating station info records
    """

    def setUp(self):
        self.authenticate()

    def authenticate(self):
        url = reverse("token_obtain_pair")

        response = self.client.post(
            url, {"username": "admin", "password": "admin"})

        self.assertEqual(response.status_code, 200)

        self.token = response.json()["access"]

        self.assertIsNotNone(self.token)
        self.client.defaults['HTTP_AUTHORIZATION'] = "Bearer " + self.token

    def test_create_initial_data(self):
        def test_create_antennas(self):
            url = reverse("antennas_list")
            data = {
                "antenna_code": "ANT1",
                "antenna_description": "test description"
            }
            response = self.client.post(url, data)

            self.assertEqual(models.Antennas.objects.count(), 1)
            self.assertEqual(response.status_code, 201)
            self.assertEqual(response.json()["antenna_code"], 'ANT1')

        def test_create_receivers(self):
            url = reverse("receivers_list")
            data = {
                "receiver_code": "RC1",
                "receiver_description": "test description"
            }
            response = self.client.post(
                url, data)

            self.assertEqual(models.Receivers.objects.count(), 1)
            self.assertEqual(response.status_code, 201)
            self.assertEqual(response.json()["receiver_code"], 'RC1')

        def test_create_networks(self):
            url = reverse("network_list")

            data = {
                "network_code": "NT1",
                "network_name": "test network"
            }

            response = self.client.post(
                url, data)

            self.assertEqual(models.Networks.objects.count(), 1)
            self.assertEqual(response.status_code, 201)
            self.assertEqual(response.json()["network_code"], 'NT1')

        def test_create_gamit_htc(self):
            url = reverse("gamit_htc_list")

            data = {
                "antenna_code": 'ANT1',
                "height_code": 'HT1'
            }

            response = self.client.post(
                url, data)

            self.assertEqual(models.GamitHtc.objects.count(), 1)
            self.assertEqual(response.status_code, 201)
            self.assertEqual(response.json()["height_code"], 'HT1')

        def test_create_station(self):
            url = reverse("station_list")

            data = {
                "network_code": 'NT1',
                "station_code": 'ST1',
                "station_name": 'test station',
                "country_code": 'USA'
            }

            response = self.client.post(
                url, data)

            self.assertEqual(models.Stations.objects.count(), 1)
            self.assertEqual(response.status_code, 201)
            self.assertEqual(response.json()["station_code"], 'ST1')

        def test_create_station_info(self):
            url = reverse("station_info_list")

            data = {
                "network_code": 'NT1',
                "station_code": 'ST1',
                "antenna_code": 'ANT1',
                "receiver_code": 'RC1',
                "height_code": 'HT1',
                "country_code": 'USA',
                "date_start": "2020-01-01T00:00:00",
                "radome_code": "R1",
            }

            response = self.client.post(
                url, data)

            self.assertEqual(response.status_code, 201)
            self.assertEqual(models.Stationinfo.objects.count(), 1)
            self.assertEqual(response.json()["network_code"], 'NT1')

        test_create_antennas(self)
        test_create_receivers(self)
        test_create_networks(self)
        test_create_gamit_htc(self)
        test_create_station(self)
        test_create_station_info(self)

    def test_stationinfo_create_validation_first_case(self):
        """
            There should be just one station info created,
            but the start date of the existing record should change
        """
        self.test_create_initial_data()

        url = reverse("station_info_list")

        data = {
            "network_code": 'NT1',
            "station_code": 'ST1',
            "antenna_code": 'ANT1',
            "receiver_code": 'RC1',
            "height_code": 'HT1',
            "country_code": 'USA',
            "date_start": "2019-01-01T00:00:00",
            "radome_code": "R1",
        }

        response = self.client.post(
            url, data)

        self.assertEqual(response.status_code, 201)

        # there should be only one station info yet
        self.assertEqual(models.Stationinfo.objects.count(), 1)

        self.assertEqual(models.Stationinfo.objects.all()[
            0].date_start.strftime("%Y-%m-%d %H:%M:%S"), "2019-01-01 00:00:00")

        # check event has been inserted
        self.assertEqual(models.Events.objects.filter(network_code="NT1", station_code="ST1",
                                                      description__contains=f"has been been modified to {models.Stationinfo.objects.all()[0].date_start.strftime('%Y-%m-%d %H:%M:%S')}").exists(), True)

    def test_stationinfo_create_validation_second_case(self):
        """
        """
        self.test_create_initial_data()

        url = reverse("station_info_list")

        data = {
            "network_code": 'NT1',
            "station_code": 'ST1',
            "antenna_code": 'ANT1',
            "receiver_code": 'RC1',
            "height_code": 'HT1',
            "country_code": 'USA',
            "date_start": "2018-01-01T00:00:00",
            "radome_code": "R2",
        }

        response = self.client.post(
            url, data)

        self.assertEqual(response.status_code, 201)

        self.assertEqual(models.Stationinfo.objects.count(), 2)

        self.assertEqual(models.Stationinfo.objects.all()[
            0].date_start.strftime("%Y-%m-%d %H:%M:%S"), "2018-01-01 00:00:00")

        self.assertEqual(models.Stationinfo.objects.all()[0].date_end, models.Stationinfo.objects.all()[
            1].date_start - datetime.timedelta(seconds=1))

        # check event has been inserted
        self.assertEqual(models.Events.objects.filter(network_code="NT1", station_code="ST1",
                                                      description__contains=f"A new station information record was added").exists(), True)

    def test_stationinfo_create_validation_third_case(self):
        """
            Overlap just the last session
        """
        self.test_create_initial_data()

        url = reverse("station_info_list")

        data = {
            "network_code": 'NT1',
            "station_code": 'ST1',
            "antenna_code": 'ANT1',
            "receiver_code": 'RC1',
            "height_code": 'HT1',
            "country_code": 'USA',
            "date_start": "2021-01-01T00:00:00",
            "radome_code": "R2",
        }

        response = self.client.post(
            url, data)

        self.assertEqual(response.status_code, 201)

        self.assertEqual(models.Stationinfo.objects.count(), 2)

        self.assertEqual(models.Stationinfo.objects.all()[
                         0].date_end, models.Stationinfo.objects.all()[
                         1].date_start - datetime.timedelta(seconds=1))

        self.assertEqual(models.Events.objects.all().filter(network_code="NT1", station_code="ST1",
                                                            description__contains=f"The previous DateEnd value was updated to {models.Stationinfo.objects.all()[0].date_end.strftime('%Y-%m-%d %H:%M:%S')}").exists(), True)

    def test_stationinfo_create_validation_forth_case(self):
        """
            Trying to insert record that overlaps the first record but not the last one.
            Error should be returned
        """
        self.test_create_initial_data()

        url = reverse("station_info_list")

        data = {
            "network_code": 'NT1',
            "station_code": 'ST1',
            "antenna_code": 'ANT1',
            "receiver_code": 'RC1',
            "height_code": 'HT1',
            "country_code": 'USA',
            "date_start": "2023-01-01T00:00:00",
            "radome_code": "R2",
        }

        response = self.client.post(
            url, data)

        self.assertEqual(response.status_code, 201)

        self.assertEqual(models.Stationinfo.objects.count(), 2)

        data = {
            "network_code": 'NT1',
            "station_code": 'ST1',
            "antenna_code": 'ANT1',
            "receiver_code": 'RC1',
            "height_code": 'HT1',
            "country_code": 'USA',
            "date_start": "2021-01-01T00:00:00",
            "date_end": "2022-01-01T00:00:00",
            "radome_code": "R2",
        }

        response = self.client.post(
            url, data)

        self.assertEqual(response.status_code, 400)

        self.assertEqual(models.Stationinfo.objects.count(), 2)

    def test_stationinfo_create_validation_fifth_case(self):
        """
            No overlaps. It should just insert the record
        """
        self.test_create_initial_data()

        # modify the date_end of the first record so it doesn't overlap with the new record

        url = reverse("station_info_detail", kwargs={
                      "pk": models.Stationinfo.objects.all()[0].api_id})

        data = {
            "network_code": 'NT1',
            "station_code": 'ST1',
            "antenna_code": 'ANT1',
            "receiver_code": 'RC1',
            "height_code": 'HT1',
            "country_code": 'USA',
            "date_start": "2020-01-01T00:00:00",
            "date_end": "2021-01-01T00:00:00",
            "radome_code": "R1",
        }

        response = self.client.put(
            url, data, content_type='application/json')

        self.assertEqual(response.status_code, 200)

        self.assertEqual(models.Stationinfo.objects.count(), 1)

        # now add the new record

        url = reverse("station_info_list")

        data = {
            "network_code": 'NT1',
            "station_code": 'ST1',
            "antenna_code": 'ANT1',
            "receiver_code": 'RC1',
            "height_code": 'HT1',
            "country_code": 'USA',
            "date_start": "2022-01-01T00:00:00",
            "radome_code": "R2",
        }

        response = self.client.post(
            url, data)

        self.assertEqual(response.status_code, 201)

        self.assertEqual(models.Stationinfo.objects.count(), 2)

    def test_stationinfo_create_validation_sixth_case(self):
        """
            Try to insert a record with the same pk.
            It should not insert the record and return an error
        """

        self.test_create_initial_data()

        url = reverse("station_info_list")

        data = {
            "network_code": 'NT1',
            "station_code": 'ST1',
            "antenna_code": 'ANT1',
            "receiver_code": 'RC1',
            "height_code": 'HT1',
            "country_code": 'USA',
            "date_start": "2020-01-01T00:00:00",
            "radome_code": "R1",
        }

        response = self.client.post(
            url, data)

        self.assertEqual(response.status_code, 400)

        self.assertEqual(models.Stationinfo.objects.count(), 1)

    def test_stationinfo_update_validation_first_case(self):
        """
            Overlap one record when trying to update.
            Error should be returned.
        """

        self.test_create_initial_data()

        # we insert a new record, that will be overlapped

        url = reverse("station_info_list")

        data = {
            "network_code": 'NT1',
            "station_code": 'ST1',
            "antenna_code": 'ANT1',
            "receiver_code": 'RC1',
            "height_code": 'HT1',
            "country_code": 'USA',
            "date_start": "2021-01-01T00:00:00",
            "radome_code": "R1",
        }

        response = self.client.post(
            url, data)

        self.assertEqual(response.status_code, 201)

        self.assertEqual(models.Stationinfo.objects.count(), 2)

        # now we try to update the first record, overlapping the second one

        url = reverse("station_info_detail", kwargs={
                      "pk": models.Stationinfo.objects.all().first().api_id})

        data = {
            "network_code": 'NT1',
            "station_code": 'ST1',
            "antenna_code": 'ANT1',
            "receiver_code": 'RC1',
            "height_code": 'HT1',
            "country_code": 'USA',
            "date_start": "2022-01-01T00:00:00",
            "radome_code": "R1",
        }

        response = self.client.put(
            url, data, content_type='application/json')

        self.assertEqual(response.status_code, 400)

        # the date start remains the same
        self.assertEqual(models.Stationinfo.objects.all().first().date_start.strftime(
            "%Y-%m-%d %H:%M:%S"), "2020-01-01 00:00:00")

    def test_stationinfo_update_validation_second_case(self):
        """
            Do not overlap any record when trying to update.
            The record should be updated
        """

        self.test_create_initial_data()

        url = reverse("station_info_detail", kwargs={
                      "pk": models.Stationinfo.objects.all().first().api_id})

        data = {
            "network_code": 'NT1',
            "station_code": 'ST1',
            "antenna_code": 'ANT1',
            "receiver_code": 'RC1',
            "height_code": 'HT1',
            "country_code": 'USA',
            "date_start": "2021-01-01T00:00:00",
            "radome_code": "R1",
        }

        response = self.client.put(
            url, data, content_type='application/json')

        self.assertEqual(response.status_code, 200)

        self.assertEqual(models.Stationinfo.objects.count(), 1)

        self.assertEqual(models.Stationinfo.objects.all().first().date_start.strftime(
            "%Y-%m-%d %H:%M:%S"), "2021-01-01 00:00:00")