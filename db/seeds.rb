# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
# coding: utf-8

User.create!(name: "システム管理者",
             email: "sample@email.com",
             password: "password",
             password_confirmation: "password",
             admin: true,
             superior: false)
             
User.create!(name: "上長1",
             email: "superior1@email.com",
             password: "password",
             password_confirmation: "password",
             admin: false,
             superior: true,
             designated_work_start_time: "09:00",
             designated_work_end_time: "18:00")

User.create!(name: "上長2",
             email: "superior2@email.com",
             password: "password",
             password_confirmation: "password",
             admin: false,
             superior: true,
             designated_work_start_time: "09:00",
             designated_work_end_time: "18:00")

User.create!(name: "一般1",
             email: "general1@email.com",
             password: "password",
             password_confirmation: "password",
             admin: false,
             superior: false,
             designated_work_start_time: "09:00",
             designated_work_end_time: "18:00")
             
User.create!(name: "一般2",
             email: "general2@email.com",
             password: "password",
             password_confirmation: "password",
             admin: false,
             superior: false,
             designated_work_start_time: "09:00",
             designated_work_end_time: "18:00")


# 5.times do |n|
#   name = Faker::Name.name
#   email ="sample-#{n+1}@email.com"
#   password = "password"
#   User.create(name: name,
#               email: email,
#               password: password,
#               password_confirmation: password,
#             designated_work_start_time: "09:00",
#             designated_work_end_time: "18:00")

# end